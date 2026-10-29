import Benchmark
import FirebladeECS

func referenceUpdateBenchmarks() {
    let entityScales = [0] + (0 ... 21).map { 1 << $0 }
    let storages: [Nexus.StorageKind] = [.archetype, .sparseSet]

    for scale in entityScales {
        for storage in storages {
            registerReferenceUpdateBenchmark(
                name: "ReferenceTwoSystemsUniform",
                storage: storage,
                entityCount: scale,
                isMixed: false
            )
            registerReferenceUpdateBenchmark(
                name: "ReferenceTwoSystemsMixed",
                storage: storage,
                entityCount: scale,
                isMixed: true
            )
        }
    }
}

private func registerReferenceUpdateBenchmark(
    name: String,
    storage: Nexus.StorageKind,
    entityCount: Int,
    isMixed: Bool
) {
    var state: (nexus: Nexus, movement: ReferenceMovementSystem, data: ReferenceDataSystem)?
    Benchmark(
        "\(name) [\(storage)] / \(entityCount)",
        closure: { benchmark in
            guard let state else {
                benchmark.error("Reference update benchmark setup did not create its state.")
                return
            }
            let deltaTime: Float = 1.0 / 60.0

            // The first warmup mutates this same world before the measured samples.
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                state.movement.update(deltaTime: deltaTime)
                state.data.update(deltaTime: deltaTime)
            }
            benchmark.stopMeasurement()
            blackHole(state.nexus.numEntities)
        },
        setup: {
            let nexus = Nexus(storage: storage)
            ReferenceUpdatePopulation.populate(nexus: nexus, entityCount: entityCount, isMixed: isMixed)
            state = (
                nexus: nexus,
                movement: ReferenceMovementSystem(nexus: nexus),
                data: ReferenceDataSystem(nexus: nexus)
            )
        },
        teardown: {
            state = nil
        }
    )
}
