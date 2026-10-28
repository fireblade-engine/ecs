// swiftformat:disable preferForLoop
import Benchmark
import FirebladeECS

func comparisonBenchmarks() {
    let updateScales = [1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 2097152]
    let destroyScales = [65536, 262144, 1048576, 2097152]
    let modScales = [1024, 16384, 65536]

    let storages: [Nexus.StorageKind] = [.archetype, .sparseSet]

    // MARK: - Update7Systems
    for scale in updateScales {
        for storage in storages {
            Benchmark("Update7Systems [\(storage)] / \(scale)") { benchmark in
                let nexus = setUpNexus(storage: storage, count: scale)
                let movement = MovementSystem(nexus: nexus)
                let data = DataSystem(nexus: nexus)
                let moreComplex = MoreComplexSystem(nexus: nexus)
                let health = HealthSystem(nexus: nexus)
                let damage = DamageSystem(nexus: nexus)
                let sprite = SpriteSystem(nexus: nexus)
                let render = RenderSystem(nexus: nexus)

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
            }
        }
    }

    // MARK: - CreateEntities2Comp
    for scale in updateScales {
        for storage in storages {
            Benchmark("CreateEntities2Comp [\(storage)] / \(scale)") { benchmark in
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    let nexus = Nexus(storage: storage)
                    for i in 0 ..< scale {
                        let entity = nexus.createEntity(with:
                            PositionComponent(x: Float(i), y: Float(i)),
                            VelocityComponent(x: 1, y: 1)
                        )
                        blackHole(entity)
                    }
                }
                benchmark.stopMeasurement()
            }
        }
    }

    // MARK: - DestroyEntities2Comp
    for scale in destroyScales {
        for storage in storages {
            Benchmark("DestroyEntities2Comp [\(storage)] / \(scale)") { benchmark in
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    let nexus = Nexus(storage: storage)
                    let entities = (0 ..< scale).map { i in
                        nexus.createEntity(with:
                            PositionComponent(x: Float(i), y: Float(i)),
                            VelocityComponent(x: 1, y: 1)
                        )
                    }
                    for entity in entities {
                        nexus.destroy(entity: entity)
                    }
                }
                benchmark.stopMeasurement()
            }
        }
    }

    // MARK: - AddRemoveComponent (Churn)
    for scale in modScales {
        for storage in storages {
            Benchmark("AddRemoveComponent [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { i in
                    nexus.createEntity(with: PositionComponent(x: Float(i), y: Float(i)))
                }
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    for entity in entities {
                        entity.set(VelocityComponent(x: 1, y: 1))
                    }
                    for entity in entities {
                        entity.remove(VelocityComponent.self)
                    }
                }
                benchmark.stopMeasurement()
            }
        }
    }

    // MARK: - GetComponent (Lookup)
    for scale in modScales {
        for storage in storages {
            Benchmark("GetComponent [\(storage)] / \(scale)") { benchmark in
                let nexus = setUpNexus(storage: storage, count: scale)
                let entities = Array(nexus.makeEntitiesIterator())
                var generator = SystemRandomNumberGenerator()
                let order = entities.shuffled(using: &generator)
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    var sum: Float = 0
                    for entity in order {
                        if let pos = entity.get(PositionComponent.self) {
                            sum += pos.x
                        }
                    }
                    blackHole(sum)
                }
                benchmark.stopMeasurement()
            }
        }
    }
}
