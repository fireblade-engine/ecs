import Benchmark
import FirebladeECS

func comparisonBenchmarks() {
    let updateScales = [1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 2097152]
    let storages: [Nexus.StorageKind] = [.archetype, .sparseSet]

    for scale in updateScales {
        for storage in storages {
            Benchmark("Update7SystemsOnly [\(storage)] / \(scale)") { benchmark in
                let nexus = setUpNexus(storage: storage, count: scale)
                let movement = MovementSystem(nexus: nexus)
                let data = DataSystem(nexus: nexus)
                let moreComplex = MoreComplexSystem(nexus: nexus)
                let health = HealthSystem(nexus: nexus)
                let damage = DamageSystem(nexus: nexus)
                let sprite = SpriteSystem(nexus: nexus)
                let render = RenderSystem(nexus: nexus)

                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    var accumulator: Float = 0
                    movement.update()
                    data.update()
                    moreComplex.update()
                    health.update()
                    damage.update()
                    sprite.update()
                    render.update(accumulator: &accumulator)
                    blackHole(accumulator)
                }
                benchmark.stopMeasurement()
            }
        }
    }
}
