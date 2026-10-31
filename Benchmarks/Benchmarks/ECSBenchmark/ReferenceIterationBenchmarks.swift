import Benchmark
import FirebladeECS

enum ReferenceIterationWorkload: String, CaseIterable, Sendable {
    case positionOnly = "PositionOnly"
    case positionVelocity = "PositionVelocity"
    case mixedPositionVelocityData = "MixedPositionVelocityData"
}

func referenceIterationBenchmarks() {
    let entityScales = [0] + (0 ... 21).map { 1 << $0 }

    for entityCount in entityScales {
        for storage in [Nexus.StorageKind.archetype, .sparseSet] {
            for workload in ReferenceIterationWorkload.allCases {
                registerReferenceIterationBenchmark(
                    workload: workload,
                    storage: storage,
                    entityCount: entityCount
                )
            }
        }
    }
}

func populateReferenceIterationPopulation(
    nexus: Nexus,
    entityCount: Int,
    workload: ReferenceIterationWorkload
) {
    switch workload {
    case .positionOnly:
        for _ in 0 ..< entityCount {
            nexus.createEntity(with: ReferencePositionComponent())
        }
    case .positionVelocity:
        for _ in 0 ..< entityCount {
            nexus.createEntity(with: ReferencePositionComponent(), ReferenceVelocityComponent())
        }
    case .mixedPositionVelocityData:
        let removalStart = 2 * entityCount / 4
        let removalEnd = 3 * entityCount / 4

        for index in 0 ..< entityCount {
            let entity = nexus.createEntity(
                with: ReferencePositionComponent(),
                ReferenceVelocityComponent(),
                ReferenceDataComponent()
            )
            let isEligible = entityCount < 100 || (index >= removalStart && index <= removalEnd)
            let removalOrdinal = index - removalStart
            let removesComponents = isEligible && (entityCount < 100 || removalOrdinal % 10 == 0)
            guard removesComponents else { continue }

            if index % 7 == 0 { entity.remove(ReferencePositionComponent.self) }
            if index % 11 == 0 { entity.remove(ReferenceVelocityComponent.self) }
            if index % 13 == 0 { entity.remove(ReferenceDataComponent.self) }
        }
    }
}

// For nonzero N, the reference per-entity graphs divide batch time by total created entities.
// This benchmark reports a full Fireblade family pass without per-entity normalization.
// Flecs query callbacks pass references; Fireblade typed forEach reads value copies.
func makeReferenceIterationOperation(
    nexus: Nexus,
    workload: ReferenceIterationWorkload
) -> () -> Void {
    switch workload {
    case .positionOnly:
        let family = nexus.family(requires: ReferencePositionComponent.self)
        return { family.forEach { (position: ReferencePositionComponent) in blackHole(position) } }
    case .positionVelocity:
        let family = nexus.family(requiresAll: ReferencePositionComponent.self, ReferenceVelocityComponent.self)
        return {
            family.forEach { (position: ReferencePositionComponent, velocity: ReferenceVelocityComponent) in
                blackHole(position)
                blackHole(velocity)
            }
        }
    case .mixedPositionVelocityData:
        let family = nexus.family(
            requiresAll: ReferencePositionComponent.self,
            ReferenceVelocityComponent.self,
            ReferenceDataComponent.self
        )
        return {
            family.forEach {
                (position: ReferencePositionComponent, velocity: ReferenceVelocityComponent, data: ReferenceDataComponent) in
                blackHole(position)
                blackHole(velocity)
                blackHole(data)
            }
        }
    }
}

private func registerReferenceIterationBenchmark(
    workload: ReferenceIterationWorkload,
    storage: Nexus.StorageKind,
    entityCount: Int
) {
    var state: (nexus: Nexus, iterate: () -> Void)?
    Benchmark(
        "ReferenceIteration\(workload.rawValue) [\(storage)] / \(entityCount)",
        closure: { benchmark in
            guard let state else {
                benchmark.error("Reference iteration benchmark setup did not create its state.")
                return
            }

            withExtendedLifetime(state.nexus) {
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    state.iterate()
                }
                benchmark.stopMeasurement()
                blackHole(state.nexus.numEntities)
            }
        },
        setup: {
            let nexus = Nexus(storage: storage)
            populateReferenceIterationPopulation(nexus: nexus, entityCount: entityCount, workload: workload)
            state = (nexus, makeReferenceIterationOperation(nexus: nexus, workload: workload))
        },
        teardown: {
            state = nil
        }
    )
}
