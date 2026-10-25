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
        let min = EntityIdentifier(index: .min, generation: .min)
        #expect(min.index == UInt32.min)
        #expect(min.generation == UInt32.min)
        #expect(min.rawValue == 0)
        #expect(min == EntityIdentifier.invalid)
        #expect(!min.isValid)

        let uRand = UInt32.random(in: UInt32.min...UInt32.max)
        let gRand = UInt32.random(in: 1...UInt32.max)
        let rand = EntityIdentifier(index: uRand, generation: gRand)
        #expect(rand.index == uRand)
        #expect(rand.generation == gRand)
        #expect(rand.isValid)
        #expect(EntityIdentifier(rawValue: rand.rawValue) == rand)

        let max = EntityIdentifier(index: .max, generation: .max)
        #expect(max.rawValue == UInt64.max)
        #expect(max != EntityIdentifier.invalid)
        #expect(max.index == UInt32.max)
        #expect(max.generation == UInt32.max)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func allComponentsOfEntity(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)

        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Hello")
        let vel = Velocity(a: 1.234)

        let entity = nexus.createEntity()
        entity.set(pos)
        entity.set(name, vel)

        let allComponents = Array(entity.makeComponentsIterator())

        #expect(allComponents.count == 3)
        #expect(allComponents.compactMap { $0 as? Position } == [pos])
        #expect(allComponents.compactMap { $0 as? Name } == [name])
        #expect(allComponents.compactMap { $0 as? Velocity } == [vel])
    }

    @Test(arguments: Nexus.StorageKind.allCases) func entityEquality(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)

        let entityA = nexus.createEntity()
        let entityB = nexus.createEntity()

        #expect(entityA == entityA)
        #expect(entityA != entityB)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func removeAllComponentsFromEntity(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)

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
            generator.markUnused(entityId: EntityIdentifier(index: UInt32(i), generation: 0))
        }

        #expect(generator.count == 51)

        for _ in 0..<50 {
            _ = generator.nextId()
        }

        #expect(generator.count == 1)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func entitySubscripts(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
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
        #expect(entity[Position.self] == pos)
        entity[Position.self] = pos // re-assign
        #expect(entity[Position.self] == pos)
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

        entity.set(Comp1(12))
        #expect(entity[\Comp1.value] == 12)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func componentsIteration(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        #expect(Array(entity.makeComponentsIterator()).isEmpty)
        entity.set(Position())
        #expect(Array(entity.makeComponentsIterator()).count == 1)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func setAndGet(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        #expect(entity.get(Position.self) == nil)

        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Hello")
        entity.set(pos).set(name)
        #expect(entity.get(Position.self) == pos)
        #expect(entity.get(Name.self) == name)

        entity.set([Velocity(a: 1), Color()] as [Component])
        #expect(entity.has(Velocity.self))
        #expect(entity.has(Color.self))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func setValueThroughWritableKeyPath(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        let keyPath: WritableKeyPath<Position, Int> = \.x

        // creates a default-initialized component
        #expect(entity.set(value: 3, for: keyPath))
        #expect(entity.get(Position.self)?.x == 3)

        // writes in place; a copy taken before does not change
        let pos = try #require(entity.get(Position.self))
        #expect(entity.set(value: 4, for: keyPath))
        #expect(pos.x == 3)
        #expect(entity.get(Position.self)?.x == 4)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func entityCreationIntrinsic(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
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

    @Test(arguments: Nexus.StorageKind.allCases) func entityDescriptions(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
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
