// swiftformat:disable preferForLoop
import Benchmark
import FirebladeECS
import FirebladeECSV1

func comparisonBenchmarks() {
    let updateScales = [1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 2097152]
    let destroyScales = [65536, 262144, 1048576, 2097152]
    let modScales = [1024, 16384, 65536]

    // MARK: - Update7Systems
    for scale in updateScales {
        Benchmark("Update7Systems [v1.4.3] / \(scale)") { benchmark in
            let nexus = setUpV1Nexus(count: scale)
            let movement = V1MovementSystem(nexus: nexus)
            let data = V1DataSystem(nexus: nexus)
            let moreComplex = V1MoreComplexSystem(nexus: nexus)
            let health = V1HealthSystem(nexus: nexus)
            let damage = V1DamageSystem(nexus: nexus)
            let sprite = V1SpriteSystem(nexus: nexus)
            let render = V1RenderSystem(nexus: nexus)

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

        Benchmark("Update7Systems [v2.0-archetype] / \(scale)") { benchmark in
            let nexus = setUpV2Nexus(storage: .archetype, count: scale)
            let movement = V2MovementSystem(nexus: nexus)
            let data = V2DataSystem(nexus: nexus)
            let moreComplex = V2MoreComplexSystem(nexus: nexus)
            let health = V2HealthSystem(nexus: nexus)
            let damage = V2DamageSystem(nexus: nexus)
            let sprite = V2SpriteSystem(nexus: nexus)
            let render = V2RenderSystem(nexus: nexus)

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

        Benchmark("Update7Systems [v2.0-sparseSet] / \(scale)") { benchmark in
            let nexus = setUpV2Nexus(storage: .sparseSet, count: scale)
            let movement = V2MovementSystem(nexus: nexus)
            let data = V2DataSystem(nexus: nexus)
            let moreComplex = V2MoreComplexSystem(nexus: nexus)
            let health = V2HealthSystem(nexus: nexus)
            let damage = V2DamageSystem(nexus: nexus)
            let sprite = V2SpriteSystem(nexus: nexus)
            let render = V2RenderSystem(nexus: nexus)

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

    // MARK: - CreateEntities2Comp
    for scale in updateScales {
        Benchmark("CreateEntities2Comp [v1.4.3] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECSV1.Nexus()
                for i in 0 ..< scale {
                    let entity = nexus.createEntity(with:
                        V1PositionComponent(x: Float(i), y: Float(i)),
                        V1VelocityComponent(x: 1, y: 1)
                    )
                    blackHole(entity)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("CreateEntities2Comp [v2.0-archetype] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECS.Nexus(storage: .archetype)
                for i in 0 ..< scale {
                    let entity = nexus.createEntity(with:
                        V2PositionComponent(x: Float(i), y: Float(i)),
                        V2VelocityComponent(x: 1, y: 1)
                    )
                    blackHole(entity)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("CreateEntities2Comp [v2.0-sparseSet] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECS.Nexus(storage: .sparseSet)
                for i in 0 ..< scale {
                    let entity = nexus.createEntity(with:
                        V2PositionComponent(x: Float(i), y: Float(i)),
                        V2VelocityComponent(x: 1, y: 1)
                    )
                    blackHole(entity)
                }
            }
            benchmark.stopMeasurement()
        }
    }

    // MARK: - DestroyEntities2Comp
    for scale in destroyScales {
        Benchmark("DestroyEntities2Comp [v1.4.3] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECSV1.Nexus()
                let entities = (0 ..< scale).map { i in
                    nexus.createEntity(with:
                        V1PositionComponent(x: Float(i), y: Float(i)),
                        V1VelocityComponent(x: 1, y: 1)
                    )
                }
                for entity in entities {
                    nexus.destroy(entity: entity)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("DestroyEntities2Comp [v2.0-archetype] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECS.Nexus(storage: .archetype)
                let entities = (0 ..< scale).map { i in
                    nexus.createEntity(with:
                        V2PositionComponent(x: Float(i), y: Float(i)),
                        V2VelocityComponent(x: 1, y: 1)
                    )
                }
                for entity in entities {
                    nexus.destroy(entity: entity)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("DestroyEntities2Comp [v2.0-sparseSet] / \(scale)") { benchmark in
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                let nexus = FirebladeECS.Nexus(storage: .sparseSet)
                let entities = (0 ..< scale).map { i in
                    nexus.createEntity(with:
                        V2PositionComponent(x: Float(i), y: Float(i)),
                        V2VelocityComponent(x: 1, y: 1)
                    )
                }
                for entity in entities {
                    nexus.destroy(entity: entity)
                }
            }
            benchmark.stopMeasurement()
        }
    }

    // MARK: - AddRemoveComponent
    for scale in modScales {
        Benchmark("AddRemoveComponent [v1.4.3] / \(scale)") { benchmark in
            let nexus = FirebladeECSV1.Nexus()
            let entities = (0 ..< scale).map { i in
                nexus.createEntity(with: V1PositionComponent(x: Float(i), y: Float(i)))
            }
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                for entity in entities {
                    entity.set(V1VelocityComponent(x: 1, y: 1))
                }
                for entity in entities {
                    entity.remove(V1VelocityComponent.self)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("AddRemoveComponent [v2.0-archetype] / \(scale)") { benchmark in
            let nexus = FirebladeECS.Nexus(storage: .archetype)
            let entities = (0 ..< scale).map { i in
                nexus.createEntity(with: V2PositionComponent(x: Float(i), y: Float(i)))
            }
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                for entity in entities {
                    entity.set(V2VelocityComponent(x: 1, y: 1))
                }
                for entity in entities {
                    entity.remove(V2VelocityComponent.self)
                }
            }
            benchmark.stopMeasurement()
        }

        Benchmark("AddRemoveComponent [v2.0-sparseSet] / \(scale)") { benchmark in
            let nexus = FirebladeECS.Nexus(storage: .sparseSet)
            let entities = (0 ..< scale).map { i in
                nexus.createEntity(with: V2PositionComponent(x: Float(i), y: Float(i)))
            }
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                for entity in entities {
                    entity.set(V2VelocityComponent(x: 1, y: 1))
                }
                for entity in entities {
                    entity.remove(V2VelocityComponent.self)
                }
            }
            benchmark.stopMeasurement()
        }
    }

    // MARK: - GetComponent
    for scale in modScales {
        Benchmark("GetComponent [v1.4.3] / \(scale)") { benchmark in
            let nexus = setUpV1Nexus(count: scale)
            let entities = Array(nexus.makeEntitiesIterator())
            var generator = SystemRandomNumberGenerator()
            let order = entities.shuffled(using: &generator)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                var sum: Float = 0
                for entity in order {
                    if let pos = entity.get(V1PositionComponent.self) {
                        sum += pos.x
                    }
                }
                blackHole(sum)
            }
            benchmark.stopMeasurement()
        }

        Benchmark("GetComponent [v2.0-archetype] / \(scale)") { benchmark in
            let nexus = setUpV2Nexus(storage: .archetype, count: scale)
            let entities = Array(nexus.makeEntitiesIterator())
            var generator = SystemRandomNumberGenerator()
            let order = entities.shuffled(using: &generator)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                var sum: Float = 0
                for entity in order {
                    if let pos = entity.get(V2PositionComponent.self) {
                        sum += pos.x
                    }
                }
                blackHole(sum)
            }
            benchmark.stopMeasurement()
        }

        Benchmark("GetComponent [v2.0-sparseSet] / \(scale)") { benchmark in
            let nexus = setUpV2Nexus(storage: .sparseSet, count: scale)
            let entities = Array(nexus.makeEntitiesIterator())
            var generator = SystemRandomNumberGenerator()
            let order = entities.shuffled(using: &generator)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                var sum: Float = 0
                for entity in order {
                    if let pos = entity.get(V2PositionComponent.self) {
                        sum += pos.x
                    }
                }
                blackHole(sum)
            }
            benchmark.stopMeasurement()
        }
    }
}
