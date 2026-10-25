// swiftformat:disable preferForLoop
import Benchmark
import FirebladeECS

// derived from FirebladeECSPerformanceTests/TypedFamilyPerformanceTests.swift in the parent project

let benchmarks: @Sendable () -> Void = {
    Benchmark("TraitMatching") { benchmark in
        let nexus = setUpNexus()
        let a = nexus.createEntity()
        a.set(Position(x: 1, y: 2))
        a.set(Name(name: "myName"))
        a.set(Velocity(a: 3.14))
        a.set(EmptyComponent())

        let isMatch = nexus.family(requiresAll: Position.self, Velocity.self,
                                   excludesAll: Party.self)

        for _ in benchmark.scaledIterations {
            blackHole(
                isMatch.canBecomeMember(a)
            )
        }
    }

    Benchmark("TypedFamilyEntities") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .entities
                    .forEach { (entity: Entity) in
                        _ = entity
                    }
            )
        }
    }

    Benchmark("TypedFamilyOneComponent") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .forEach { (position: Position) in
                        _ = position
                    }
            )
        }
    }

    Benchmark("TypedFamilyEntityOneComponent") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .entityAndComponents
                    .forEach { (entity: Entity, position: Position) in
                        _ = entity
                        _ = position
                    }
            )
        }
    }

    Benchmark("TypedFamilyTwoComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .forEach { (position: Position, velocity: Velocity) in
                        _ = position
                        _ = velocity
                    }
            )
        }
    }
    Benchmark("TypedFamilyEntityTwoComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .entityAndComponents
                    .forEach { (entity: Entity, position: Position, velocity: Velocity) in
                        _ = entity
                        _ = position
                        _ = velocity
                    }
            )
        }
    }

    Benchmark("TypedFamilyThreeComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .forEach { (position: Position, velocity: Velocity, name: Name) in
                        _ = position
                        _ = velocity
                        _ = name
                    }
            )
        }
    }
    Benchmark("TypedFamilyEntityThreeComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .entityAndComponents
                    .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name) in
                        _ = entity
                        _ = position
                        _ = velocity
                        _ = name
                    }
            )
        }
    }

    Benchmark("TypedFamilyFourComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .forEach { (position: Position, velocity: Velocity, name: Name, color: Color) in
                        _ = position
                        _ = velocity
                        _ = name
                        _ = color
                    }
            )
        }
    }

    Benchmark("TypedFamilyEntityFourComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, excludesAll: Party.self)
        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .entityAndComponents
                    .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name, color: Color) in
                        _ = entity
                        _ = position
                        _ = velocity
                        _ = name
                        _ = color
                    }
            )
        }
    }

    Benchmark("TypedFamilyFiveComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self, excludesAll: Party.self)

        for _ in benchmark.scaledIterations {
            blackHole(
                family
                    .forEach { (position: Position, velocity: Velocity, name: Name, color: Color, empty: EmptyComponent) in
                        _ = position
                        _ = velocity
                        _ = name
                        _ = color
                        _ = empty
                    }
            )
        }
    }

    Benchmark("TypedFamilyEntityFiveComponents") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self, excludesAll: Party.self)

        for _ in benchmark.scaledIterations {
            blackHole(family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name, color: Color, empty: EmptyComponent) in
                    _ = entity
                    _ = position
                    _ = velocity
                    _ = name
                    _ = color
                    _ = empty
                }
            )
        }
    }

    // One sample per run: the family must be new, so each run sets up its own nexus outside the measurement.
    Benchmark("FamilyCreation", configuration: .init(scalingFactor: .one)) { benchmark in
        let nexus = setUpNexus()
        benchmark.startMeasurement()
        blackHole(nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self))
        benchmark.stopMeasurement()
    }

    Benchmark("EntitiesIteration") { benchmark in
        let nexus = setUpNexus()
        for _ in benchmark.scaledIterations {
            blackHole(
                nexus
                    .makeEntitiesIterator()
                    .forEach { (entity: Entity) in
                        _ = entity
                    }
            )
        }
    }

    // Membership churn on an existing family: components leave and rejoin, entities are created and destroyed.
    Benchmark("FamilyChurn") { benchmark in
        let nexus = setUpNexus()
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        let entities = Array(family.entities.prefix(1000))
        for _ in benchmark.scaledIterations {
            for entity in entities {
                entity.remove(Velocity.self)
            }
            for entity in entities {
                entity.set(Velocity(a: 3.14))
            }
            let spawned = (0 ..< 1000).map { index in
                nexus.createEntity(with: Position(x: index, y: index), Velocity(a: 1))
            }
            for entity in spawned {
                nexus.destroy(entity: entity)
            }
            blackHole(family.count)
        }
    }

    // MARK: Iteration only

    // The benchmarks above build their nexus inside the measured closure, so setup dominates their time and malloc counts.
    // These variants build the nexus first and measure the iteration alone: the malloc count is the allocations of the
    // iteration itself, which is 0 when iterating allocates nothing per entity.
    func iterationOnly(_ name: String, prepare: @escaping @Sendable (Nexus) -> () -> Void) {
        Benchmark(name) { benchmark in
            let nexus = setUpNexus()
            let iterate = prepare(nexus)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                iterate()
            }
            benchmark.stopMeasurement()
        }
    }

    iterationOnly("IterOnlyEntities") { nexus in
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        return { family.entities.forEach { (entity: Entity) in blackHole(entity) } }
    }

    iterationOnly("IterOnlyOneComponent") { nexus in
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        return { family.forEach { (position: Position) in blackHole(position) } }
    }

    iterationOnly("IterOnlyEntityOneComponent") { nexus in
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        return { family.entityAndComponents.forEach { (entity: Entity, position: Position) in blackHole(entity); blackHole(position) } }
    }

    iterationOnly("IterOnlyTwoComponents") { nexus in
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        return { family.forEach { (position: Position, velocity: Velocity) in blackHole(position); blackHole(velocity) } }
    }

    iterationOnly("IterOnlyEntityTwoComponents") { nexus in
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        return { family.entityAndComponents.forEach { (entity: Entity, position: Position, velocity: Velocity) in
            blackHole(entity); blackHole(position); blackHole(velocity)
        } }
    }

    iterationOnly("IterOnlyThreeComponents") { nexus in
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)
        return { family.forEach { (position: Position, velocity: Velocity, name: Name) in
            blackHole(position); blackHole(velocity); blackHole(name)
        } }
    }
}
