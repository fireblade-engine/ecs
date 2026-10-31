import FirebladeECS
import Testing
@testable import ECSCompatSuite

private let iterationCounts = [0, 1, 2, 3, 16, 17, 99, 100, 101, 512]

/// Independent restatement of the upstream recipe: which indices lose which component.
private func expectedMixedThree(count: Int) -> (removed: [Int: Set<Int>], matches: Int) {
    var removed: [Int: Set<Int>] = [:]
    let band = Array(count / 2 ... max(count / 2, 3 * count / 4))
    let eligible: [Int] = count < 100 ? Array(0 ..< count) : band.enumerated().filter { $0.offset % 10 == 0 }.map(\.element)
    for index in eligible where index < count {
        for (slot, divisor) in [7, 11, 13].enumerated() where index % divisor == 0 {
            removed[index, default: []].insert(slot)
        }
    }
    let untouched = (0 ..< count).filter { removed[$0] == nil }.count
    return (removed, untouched)
}

@Suite
struct CompatIterationTests {
    @Test
    func iterationOneVisitsEveryCreatedEntity() {
        for backend in CompatSuite.backends {
            for count in iterationCounts {
                let state = CompatWorkload.iterationOne.prepare(backend: backend, count: count)
                #expect(state.nexus.numEntities == count)
                #expect(state.family?.matched == count)
                let outcome = CompatWorkload.iterationOne.run(state, count: count)
                #expect(outcome.operations == count)
                #expect(state.nexus.numComponents == count)
            }
        }
    }

    @Test
    func iterationTwoVisitsEveryMinimalEntity() {
        for backend in CompatSuite.backends {
            for count in iterationCounts {
                let state = CompatWorkload.iterationTwo.prepare(backend: backend, count: count)
                #expect(state.nexus.numEntities == count)
                #expect(state.nexus.numComponents == count * 2)
                #expect(state.family?.matched == count)
                #expect(CompatWorkload.iterationTwo.run(state, count: count).operations == count)
            }
        }
    }

    @Test
    func mixedThreeKeepsCreatedMatchedAndVisitedDistinct() {
        for backend in CompatSuite.backends {
            for count in iterationCounts {
                let expected = expectedMixedThree(count: count)
                let state = CompatWorkload.iterationMixedThree.prepare(backend: backend, count: count)
                #expect(state.nexus.numEntities == count, "created N=\(count)")
                #expect(state.family?.matched == expected.matches, "matched N=\(count)")
                let outcome = CompatWorkload.iterationMixedThree.run(state, count: count)
                #expect(outcome.operations == expected.matches, "visited N=\(count)")
                let removedComponents = expected.removed.values.reduce(0) { $0 + $1.count }
                #expect(state.nexus.numComponents == count * 3 - removedComponents, "components N=\(count)")
            }
        }
    }

    @Test
    func mixedThreeBoundaryBehavior() {
        // Below 100 every index is eligible, so index 0 loses all three and N=1 matches nothing.
        let one = expectedMixedThree(count: 1)
        #expect(one.matches == 0)
        #expect(CompatWorkload.mixedThreeRemovals(index: 0, count: 1) == (true, true, true))
        // At 100 only the band [50, 75] every tenth ordinal (50, 60, 70) is eligible; 70 is divisible by 7.
        #expect(CompatWorkload.mixedThreeRemovals(index: 70, count: 100) == (true, false, false))
        #expect(CompatWorkload.mixedThreeRemovals(index: 7, count: 100) == (false, false, false))
        #expect(CompatWorkload.mixedThreeRemovals(index: 7, count: 99) == (true, false, false))
        for count in [99, 100, 512] {
            let expected = expectedMixedThree(count: count)
            for index in 0 ..< count {
                let removal = CompatWorkload.mixedThreeRemovals(index: index, count: count)
                let slots = expected.removed[index] ?? []
                #expect(removal.first == slots.contains(0) && removal.second == slots.contains(1) && removal.third == slots.contains(2))
            }
        }
    }

    @Test
    func iterationIsRepeatableAndDoesNotMutate() {
        for backend in CompatSuite.backends {
            for workload in [CompatWorkload.iterationOne, .iterationTwo, .iterationMixedThree] {
                let state = workload.prepare(backend: backend, count: 101)
                let components = state.nexus.numComponents
                let first = workload.run(state, count: 101)
                let second = workload.run(state, count: 101)
                #expect(first == second)
                #expect(state.nexus.numComponents == components)
            }
        }
    }

    @Test
    func iteratedComponentsCarryTheirValues() {
        for backend in CompatSuite.backends {
            let nexus = CompatSuite.makeNexus(backend: backend)
            for index in 0 ..< 5 {
                nexus.createEntity(with: CompatFirstComponent(value: index), CompatSecondComponent(value: index * 2))
            }
            let family = nexus.family(requiresAll: CompatFirstComponent.self, CompatSecondComponent.self)
            var seen = 0
            for (first, second) in family {
                #expect(second.value == first.value * 2)
                seen += 1
            }
            #expect(seen == 5)
        }
    }
}
