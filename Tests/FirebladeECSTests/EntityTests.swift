//
//  EntityTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 22.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct EntityTests {
    @Test func entityIdentifierAndIndex() {
        let min = EntityIdentifier(.min)
        #expect(min.id == UInt32.min)

        let uRand = UInt32.random(in: UInt32.min...UInt32.max)
        let rand = EntityIdentifier(uRand)
        #expect(rand.id == uRand)

        let max = EntityIdentifier(.max)
        #expect(max == EntityIdentifier.invalid)
        #expect(max.id == UInt32.max)
    }

    @Test func allComponentsOfEntity() {
        let nexus = Nexus()

        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Hello")
        let vel = Velocity(a: 1.234)

        let entity = nexus.createEntity()
        entity.assign(pos)
        entity.assign(name, vel)

        let expectedComponents: [Component] = [pos, name, vel]
        let allComponents = Array(entity.makeComponentsIterator())

        #expect(allComponents.elementsEqualUnordered(expectedComponents) { $0 === $1 })
    }

    @Test func entityEquality() {
        let nexus = Nexus()

        let entityA = nexus.createEntity()
        let entityB = nexus.createEntity()

        #expect(entityA == entityA)
        #expect(entityA != entityB)
    }

    @Test func removeAllComponentsFromEntity() {
        let nexus = Nexus()

        let entity = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "MyEntity"))
        #expect(entity.numComponents == 2)
        entity.removeAll()
        #expect(entity.numComponents == 0)
    }

    @Test func entityIdGenerator() {
        let generator = DefaultEntityIdGenerator()

        #expect(generator.count == 1)

        for _ in 0..<100 {
            _ = generator.nextId()
        }

        #expect(generator.count == 1)

        for i in 10..<60 {
            generator.markUnused(entityId: EntityIdentifier(UInt32(i)))
        }

        #expect(generator.count == 51)

        for _ in 0..<50 {
            _ = generator.nextId()
        }

        #expect(generator.count == 1)
    }

    @Test func entitySubscripts() {
        let nexus = Nexus()
        let pos = Position(x: 12, y: 45)
        let name = Name(name: "SomeName")
        let entity = nexus.createEntity(with: pos, name)

        #expect(entity[\Position.x] == 12)
        #expect(entity[\Position.y] == 45)
        #expect(entity[\Name.name] == "SomeName")

        entity[\Position.x] = 67
        entity[\Position.y] = 89
        entity[\Name.name] = "AnotherName"

        #expect(entity[\Position.x] == 67)
        #expect(entity[\Position.y] == 89)
        #expect(entity[\Name.name] == "AnotherName")

        entity[\Velocity.a] = 123
        #expect(entity[\Velocity.a] == 123.0)

        entity[Position.self]?.x = 1234
        #expect(entity[Position.self]?.x == 1234)
        #expect(entity[Velocity.self]?.a == 123.0)

        // remove position component
        entity[Position.self] = nil
        #expect(entity[Position.self] == nil)
        entity[Position.self] = pos // assign position comp instance
        #expect(entity[Position.self] === pos)
        entity[Position.self] = pos // re-assign
        #expect(entity[Position.self] === pos)
        entity[Position.self] = nil // remove position component
        #expect(entity[Position.self] == nil)

        let opts = Optionals(1, 2, "hello")
        entity[Optionals.self] = opts
        #expect(entity[Optionals.self] == opts)

        entity[\Optionals.float] = nil
        #expect(entity[\Optionals.float] == nil)
        #expect(entity[\Optionals.int] == 1)
        #expect(entity[\Optionals.string] == "hello")

        entity[Optionals.self] = nil
        #expect(entity[Optionals.self] == nil)
        entity[\Optionals.string] = "world"
        #expect(entity[\Optionals.string] == "world")

        entity.assign(Comp1(12))
        #expect(entity[\Comp1.value] == 12)
    }

    @Test func componentsIteration() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        #expect(Array(entity.makeComponentsIterator()).isEmpty)
        entity.assign(Position())
        #expect(Array(entity.makeComponentsIterator()).count == 1)
    }

    @Test func entityCreationIntrinsic() {
        let nexus = Nexus()
        let entity = nexus.createEntity()

        let secondEntity = entity.createEntity()
        #expect(secondEntity != entity)

        let thirdEntity = secondEntity.createEntity()
        #expect(secondEntity != thirdEntity)
        #expect(entity != thirdEntity)

        let entityWithComponents = entity.createEntity(with: Position(), Name())
        #expect(entityWithComponents.has(Position.self))
        #expect(entityWithComponents.has(Name.self))

        #expect(nexus.numEntities == 4)
        #expect(nexus.numComponents == 2)
    }

    @Test func entityDescriptions() {
        let nexus = Nexus()
        let entt = nexus.createEntity()
        #expect(!entt.description.isEmpty)
        #expect(!entt.debugDescription.isEmpty)
    }
}

extension Sequence {
    func elementsEqualUnordered<OtherSequence>(_ other: OtherSequence, by areEquivalent: (Element, OtherSequence.Element) throws -> Bool) rethrows -> Bool where OtherSequence: Sequence {
        for element in self {
            if try !other.contains(where: { try areEquivalent(element, $0) }) {
                return false
            }
        }
        return true
    }
}
