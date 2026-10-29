import Benchmark
import FirebladeECS

func commonBenchmarks() {
    for count in [1, 4, 16, 64, 256, 1024, 4096, 16384, 65536] {
        Benchmark("EntityIteration / \(count)") { benchmark in
            let nexus = makeComparableNexus()
            for _ in 0 ..< count {
                nexus.createEntity()
            }
            precondition(nexus.numEntities == count)

            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                for entity in nexus.makeEntitiesIterator() {
                    blackHole(entity)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("FamilyEntityIteration / \(count)") { benchmark in
            let (nexus, family) = makeFamily(count: count)
            precondition(family.count == count)

            withExtendedLifetime(nexus) {
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    for entity in family.entities {
                        blackHole(entity)
                    }
                }
                benchmark.stopMeasurement()
            }
        }

        Benchmark("FamilyComponentIteration / \(count)") { benchmark in
            let (nexus, family) = makeFamily(count: count)
            precondition(family.count == count)

            withExtendedLifetime(nexus) {
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    family.forEach { (position: HarnessPosition) in
                        blackHole(position.value)
                    }
                }
                benchmark.stopMeasurement()
            }
        }
    }
}

private func makeFamily(count: Int) -> (Nexus, Family<HarnessPosition>) {
    let nexus = makeComparableNexus()
    for value in 0 ..< count {
        nexus.createEntity(with: HarnessPosition(value: value))
    }
    return (nexus, nexus.family(requires: HarnessPosition.self))
}

private func makeComparableNexus() -> Nexus {
#if FIREBLADE_HAS_MODERN_SUITE
    return Nexus(storage: .archetype)
#else
    return Nexus()
#endif
}
