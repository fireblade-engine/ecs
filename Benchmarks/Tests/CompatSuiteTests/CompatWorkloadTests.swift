import FirebladeECS
import Testing
@testable import ECSCompatSuite

/// Empty, single, even, odd and larger counts.
private let counts = [0, 1, 2, 3, 16, 17, 1024]

private func forEachFixture(_ body: (String, Int) -> Void) {
    for backend in CompatSuite.backends {
        for count in counts {
            body(backend, count)
        }
    }
}

@Suite
struct CompatWorkloadTests {
    // MARK: - Catalog

    @Test
    func identitiesAreUniqueAndStable() {
        let identities = CompatWorkload.allCases.map(\.identity)
        #expect(Set(identities).count == identities.count)
        #expect(Set(CompatWorkload.allCases.map(\.upstreamName)).count == identities.count)
        #expect(identities.contains("entity.create.empty"))
        #expect(identities.contains("entity.create.no-entities"))
        for workload in CompatWorkload.allCases {
            #expect(["entity", "component", "iteration", "system", "event"].contains(String(workload.identity.prefix { $0 != "." })))
            #expect(!workload.identity.contains(" "))
        }
    }

    @Test
    func benchmarkNamesAreUniqueAndStartWithIdentity() {
        var names: Set<String> = []
        for workload in CompatWorkload.allCases {
            for scale in workload.registeredScales {
                for backend in CompatSuite.backends {
                    let name = workload.benchmarkName(backend: backend, scale: scale)
                    #expect(names.insert(name).inserted)
                    #expect(name.hasPrefix(workload.identity + " ["))
                }
            }
        }
        #expect(CompatWorkload.scales.contains(CompatWorkload.smallScale))
    }

    @Test
    func parityNotesAreMachineReadable() {
        for workload in CompatWorkload.allCases {
            let note = workload.parity.note
            #expect(note == "equivalent" || (note.hasPrefix("adapted(") && note.hasSuffix(")") && note.count > "adapted()".count))
        }
        #expect(CompatWorkload.add.parity.note.hasPrefix("adapted("))
        // No workload is labelled equivalent without cited evidence; none has any.
        #expect(CompatWorkload.allCases.allSatisfy { $0.parity != .equivalent })
        for workload in [CompatWorkload.lookupNone, .lookupOne, .lookupTwo, .removeAdd] {
            #expect(workload.parity.note.hasPrefix("adapted("), "\(workload.identity)")
        }
        for workload in CompatWorkload.allCases where workload.persistsState {
            #expect(workload.parity.note.contains("pass count is pinned"), "\(workload.identity)")
        }
        #expect(CompatWorkload.eventPublishMixed.parity.note.contains("base-only mixed population"))
        #expect(CompatWorkload.eventPublishUpdateMixed.parity.note.contains("base-only mixed population"))
    }

    @Test
    func persistsStateMatchesPreparedRunnerAndScalesAreIntended() {
        let persistent: Set<CompatWorkload> = [
            .systemBasicUniform, .systemBasicMixed, .systemComplexUniform, .systemComplexMixed,
            .eventPublishMixed, .eventPublishUpdateMixed
        ]
        #expect(CompatWorkload.scales == [0, 1, 16, 1024])
        #expect(CompatWorkload.smallScale == 16)
        for workload in CompatWorkload.allCases {
            #expect(workload.persistsState == persistent.contains(workload), "\(workload.identity)")
            for backend in CompatSuite.backends {
                let state = workload.prepare(backend: backend, count: 16)
                #expect((state.runner != nil) == workload.persistsState, "\(workload.identity)")
            }
            #expect(workload.registeredScales == (workload == .createNoEntities ? [0] : [0, 1, 16, 1024]), "\(workload.identity)")
        }
        #expect(CompatWorkload.persistentWarmupIterations > 0)
        #expect(CompatWorkload.persistentIterations > 0)
    }

    @Test
    func adapterReflectsComponentModelOfRevision() {
        #expect(((CompatFirstComponent.self as Any.Type) is AnyClass) == CompatSuite.usesClassComponents)
        #expect(!CompatSuite.backends.isEmpty)
    }

    // MARK: - Creation and destruction

    @Test
    func createNoEntitiesCreatesNothingAtAnyScale() {
        forEachFixture { backend, count in
            let state = CompatWorkload.createNoEntities.prepare(backend: backend, count: count)
            let outcome = CompatWorkload.createNoEntities.run(state, count: count)
            #expect(outcome == CompatOutcome())
            #expect(state.nexus.numEntities == 0)
            #expect(state.nexus.numComponents == 0)
        }
    }

    @Test
    func createEmptyCreatesExactlyCountEntities() {
        forEachFixture { backend, count in
            let state = CompatWorkload.createEmpty.prepare(backend: backend, count: count)
            #expect(state.nexus.numEntities == 0)
            let outcome = CompatWorkload.createEmpty.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == count)
            #expect(state.nexus.numEntities == count)
            #expect(state.nexus.numComponents == 0)
        }
    }

    @Test
    func createMinimalCreatesCountEntitiesWithTwoComponentsEach() {
        forEachFixture { backend, count in
            let state = CompatWorkload.createMinimal.prepare(backend: backend, count: count)
            let outcome = CompatWorkload.createMinimal.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(state.nexus.numEntities == count)
            #expect(state.nexus.numComponents == count * 2)
        }
    }

    @Test
    func destroyMinimalDestroysEachEntityOnce() {
        forEachFixture { backend, count in
            let state = CompatWorkload.destroyMinimal.prepare(backend: backend, count: count)
            #expect(state.nexus.numEntities == count)
            #expect(state.nexus.numComponents == count * 2)
            let outcome = CompatWorkload.destroyMinimal.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == count)
            #expect(state.nexus.numEntities == 0)
            #expect(state.nexus.numComponents == 0)
        }
    }

    // MARK: - Lookup

    @Test
    func lookupNoneMissesEveryEntity() {
        forEachFixture { backend, count in
            let state = CompatWorkload.lookupNone.prepare(backend: backend, count: count)
            #expect(state.nexus.numEntities == count)
            let outcome = CompatWorkload.lookupNone.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == 0)
            #expect(state.entities.filter { $0.get(CompatThirdComponent.self) != nil }.isEmpty)
            #expect(state.nexus.numComponents == 0)
        }
    }

    @Test
    func lookupOneHitsEveryEntityWithItsValue() {
        forEachFixture { backend, count in
            let state = CompatWorkload.lookupOne.prepare(backend: backend, count: count)
            let outcome = CompatWorkload.lookupOne.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == count)
            #expect(state.entities.count == count)
            for (index, entity) in state.entities.enumerated() {
                #expect(entity.get(CompatFirstComponent.self)?.value == index)
            }
            #expect(state.nexus.numComponents == count * 2)
        }
    }

    @Test
    func lookupTwoPerformsTwoGetsPerEntity() {
        forEachFixture { backend, count in
            let state = CompatWorkload.lookupTwo.prepare(backend: backend, count: count)
            let outcome = CompatWorkload.lookupTwo.run(state, count: count)
            #expect(outcome.operations == count * 2)
            #expect(outcome.hits == count * 2)
            for (index, entity) in state.entities.enumerated() {
                #expect(entity.get(CompatFirstComponent.self)?.value == index)
                #expect(entity.get(CompatSecondComponent.self)?.value == index * 2)
            }
        }
    }

    @Test
    func lookupMixedThreeLooksUpCeilHalfOfTheEntities() {
        forEachFixture { backend, count in
            let state = CompatWorkload.lookupMixedThree.prepare(backend: backend, count: count)
            let looked = (count + 1) / 2
            #expect(state.nexus.numEntities == count)
            #expect(state.entities.count == looked)
            #expect(state.nexus.numComponents == count * 2 + looked)
            let outcome = CompatWorkload.lookupMixedThree.run(state, count: count)
            #expect(outcome.operations == looked * 3)
            #expect(outcome.hits == looked * 3)
            for (position, entity) in state.entities.enumerated() {
                let index = position * 2
                let (first, second, third) = entity.get(
                    components: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self
                )
                #expect(first?.value == index)
                #expect(second?.value == index * 2)
                #expect(third?.value == index * 3)
            }
        }
    }

    // MARK: - Mutation

    @Test
    func removeAddReturnsToStartingOccupancy() {
        forEachFixture { backend, count in
            let state = CompatWorkload.removeAdd.prepare(backend: backend, count: count)
            let outcome = CompatWorkload.removeAdd.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == count)
            #expect(state.nexus.numEntities == count)
            #expect(state.nexus.numComponents == count * 2)
            for (index, entity) in state.entities.enumerated() {
                #expect(entity.get(CompatFirstComponent.self)?.value == index)
                #expect(entity.get(CompatSecondComponent.self)?.value == index * 2)
            }
        }
    }

    @Test
    func removeStepActuallyRemovesTheComponent() {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.removeAdd.prepare(backend: backend, count: 3)
            for entity in state.entities {
                #expect(entity.has(CompatFirstComponent.self))
                entity.remove(CompatFirstComponent.self)
                #expect(!entity.has(CompatFirstComponent.self))
                #expect(entity.has(CompatSecondComponent.self))
            }
            #expect(state.nexus.numComponents == 3)
        }
    }

    @Test
    func addRestoresComponentRemovedBeforeTiming() {
        forEachFixture { backend, count in
            let state = CompatWorkload.add.prepare(backend: backend, count: count)
            #expect(state.nexus.numEntities == count)
            #expect(state.nexus.numComponents == count)
            #expect(state.entities.allSatisfy { !$0.has(CompatFirstComponent.self) })

            let outcome = CompatWorkload.add.run(state, count: count)
            #expect(outcome.operations == count)
            #expect(outcome.hits == count)
            #expect(state.nexus.numComponents == count * 2)
            for (index, entity) in state.entities.enumerated() {
                #expect(entity.get(CompatFirstComponent.self)?.value == index)
            }
        }
    }

    // MARK: - Repetition

    @Test
    func repeatedInvocationsOnFreshStateDoTheSameWork() {
        for backend in CompatSuite.backends {
            for workload in CompatWorkload.allCases {
                var outcomes: [CompatOutcome] = []
                var occupancy: [[Int]] = []
                for _ in 0 ..< 3 {
                    let state = workload.prepare(backend: backend, count: 17)
                    outcomes.append(workload.run(state, count: 17))
                    occupancy.append([state.nexus.numEntities, state.nexus.numComponents])
                }
                #expect(Set(outcomes.map(\.operations)).count == 1, "\(workload.identity)")
                #expect(outcomes[0] == outcomes[1] && outcomes[1] == outcomes[2], "\(workload.identity)")
                #expect(occupancy[0] == occupancy[1] && occupancy[1] == occupancy[2], "\(workload.identity)")
            }
        }
    }

    @Test
    func repeatedRemoveAddOnSameStateKeepsOccupancy() {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.removeAdd.prepare(backend: backend, count: 17)
            let first = CompatWorkload.removeAdd.run(state, count: 17)
            let second = CompatWorkload.removeAdd.run(state, count: 17)
            #expect(first == second)
            #expect(state.nexus.numComponents == 34)
        }
    }
}
