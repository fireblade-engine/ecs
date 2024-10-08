import Benchmark
import FirebladeECS

// derived from FirebladeECSPerformanceTests/TypedFamilyPerformanceTests.swift in the parent project

let benchmarks = {
    Benchmark("TraitMatching") { benchmark in
        let nexus = setUpNexus()
        let a = nexus.createEntity()
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())

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
}
