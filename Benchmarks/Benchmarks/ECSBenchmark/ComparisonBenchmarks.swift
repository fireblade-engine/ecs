// swiftformat:disable preferForLoop
import Benchmark
import FirebladeECS

func comparisonBenchmarks() {
    let updateScales = [1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 2097152]
    let entityScales = [0, 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152]

    let storages: [Nexus.StorageKind] = [.archetype, .sparseSet]

    // MARK: - Update7Systems
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

    // Create/Destroy Swift timings exclude Nexus teardown; the reference loop includes registry teardown, so timed boundaries differ.
    // MARK: - CreateEmptyEntities / CreateEntities
    for scale in entityScales {
        for storage in storages {
            Benchmark("CreateEmptyEntities [\(storage)] / \(scale)", configuration: .init(scalingFactor: .one)) { benchmark in
                let nexus = Nexus(storage: storage)
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for _ in 0 ..< scale {
                            nexus.createEntity()
                        }
                    }
                    benchmark.stopMeasurement()
                    blackHole(nexus.numEntities)
                }
            }

            Benchmark("CreateEntities [\(storage)] / \(scale)", configuration: .init(scalingFactor: .one)) { benchmark in
                let nexus = Nexus(storage: storage)
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for _ in 0 ..< scale {
                            nexus.createEntity(with:
                                PositionComponent(x: 0, y: 0),
                                VelocityComponent(x: 1, y: 1)
                            )
                        }
                    }
                    benchmark.stopMeasurement()
                    blackHole(nexus.numEntities)
                }
            }
        }
    }

    // MARK: - DestroyEntities
    for scale in entityScales {
        for storage in storages {
            Benchmark("DestroyEntities [\(storage)] / \(scale)", configuration: .init(scalingFactor: .one)) { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { _ in
                    nexus.createEntity(with:
                        PositionComponent(x: 0, y: 0),
                        VelocityComponent(x: 1, y: 1)
                    )
                }
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            nexus.destroy(entity: entity)
                        }
                    }
                    benchmark.stopMeasurement()
                    blackHole(nexus.numEntities)
                }
            }
        }
    }

    // MARK: - RemoveAddComponent
    for scale in entityScales {
        for storage in storages {
            Benchmark("RemoveAddComponent [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { _ in
                    nexus.createEntity(with:
                        PositionComponent(x: 0, y: 0),
                        VelocityComponent(x: 1, y: 1)
                    )
                }
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            entity.remove(PositionComponent.self)
                            entity.set(PositionComponent(x: 0, y: 0))
                        }
                    }
                    benchmark.stopMeasurement()
                }
            }
        }
    }

    // MARK: - AddComponent
    for scale in entityScales {
        for storage in storages {
            Benchmark("AddComponent [\(storage)] / \(scale)", configuration: .init(scalingFactor: .one)) { benchmark in
                let nexus = Nexus(storage: storage)
                // Swift removes Position from the whole batch before timing. Upstream pauses to remove each entity just before its add,
                // so archetype occupancy and timing differ.
                let entities = (0 ..< scale).map { _ in
                    nexus.createEntity(with:
                        PositionComponent(x: 0, y: 0),
                        VelocityComponent(x: 1, y: 1)
                    )
                }
                for entity in entities {
                    entity.remove(PositionComponent.self)
                }
                assert(nexus.numEntities == scale)
                assert(nexus.numComponents == scale)
                assert(entities.allSatisfy { !$0.has(PositionComponent.self) })
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            entity.set(PositionComponent(x: 0, y: 0))
                        }
                    }
                    benchmark.stopMeasurement()
                    assert(nexus.numComponents == scale * 2)
                    assert(entities.allSatisfy { $0.has(PositionComponent.self) })
                    blackHole(nexus.numComponents)
                }
            }
        }
    }

    // MARK: - UnpackOneComponent / UnpackTwoComponents
    for scale in entityScales {
        for storage in storages {
            Benchmark("UnpackOneComponent [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { _ in
                    nexus.createEntity(with:
                        PositionComponent(x: 0, y: 0),
                        VelocityComponent(x: 1, y: 1)
                    )
                }
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            blackHole(entity.get(components: PositionComponent.self))
                        }
                    }
                    benchmark.stopMeasurement()
                }
            }

            Benchmark("UnpackTwoComponents [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { _ in
                    nexus.createEntity(with:
                        PositionComponent(x: 0, y: 0),
                        VelocityComponent(x: 1, y: 1)
                    )
                }
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            let (position, velocity) = entity.get(components: PositionComponent.self, VelocityComponent.self)
                            blackHole(position)
                            blackHole(velocity)
                        }
                    }
                    benchmark.stopMeasurement()
                }
            }

            // The reference helper fails to append odd-indexed entities to its output vector. It creates them
            // without the third component, but only the even-indexed, three-component entities are looked up.
            Benchmark("UnpackThreeComponents [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                var entities: [Entity] = []
                entities.reserveCapacity(scale)
                for index in 0 ..< scale {
                    if index.isMultiple(of: 2) {
                        entities.append(nexus.createEntity(with:
                            PositionComponent(x: 0, y: 0),
                            VelocityComponent(x: 1, y: 1),
                            DataComponent(a: 0, b: 0)
                        ))
                    } else {
                        nexus.createEntity(with:
                            PositionComponent(x: 0, y: 0),
                            VelocityComponent(x: 1, y: 1)
                        )
                    }
                }
                assert(nexus.numEntities == scale)
                assert(entities.count == (scale + 1) / 2)
                assert(nexus.numComponents == scale * 2 + entities.count)
                assert(entities.allSatisfy { $0.has(DataComponent.self) })
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            let (position, velocity, data) = entity.get(
                                components: PositionComponent.self,
                                VelocityComponent.self,
                                DataComponent.self
                            )
                            blackHole(position)
                            blackHole(velocity)
                            blackHole(data)
                        }
                    }
                    benchmark.stopMeasurement()
                }
            }

            Benchmark("UnpackNoComponent [\(storage)] / \(scale)") { benchmark in
                let nexus = Nexus(storage: storage)
                let entities = (0 ..< scale).map { _ in nexus.createEntity() }
                withExtendedLifetime(nexus) {
                    benchmark.startMeasurement()
                    for _ in benchmark.scaledIterations {
                        for entity in entities {
                            blackHole(entity.get(components: DataComponent.self))
                        }
                    }
                    benchmark.stopMeasurement()
                }
            }
        }
    }
}
