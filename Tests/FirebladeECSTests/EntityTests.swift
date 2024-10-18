//
//  EntityTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 22.10.17.
//

@testable import FirebladeECS
import XCTest

class EntityTests: XCTestCase {
    func testEntityIdentifierAndIndex() {
        let min = EntityIdentifier(.min)
        XCTAssertEqual(min.id, UInt32.min)

        let uRand = UInt32.random(in: UInt32.min...UInt32.max)
        let rand = EntityIdentifier(uRand)
        XCTAssertEqual(rand.id, uRand)

        let max = EntityIdentifier(.max)
        XCTAssertEqual(max, EntityIdentifier.invalid)
        XCTAssertEqual(max.id, UInt32.max)
    }

//    func testAllComponentsOfEntity() {
//        let nexus = Nexus()
//
//        let pos = Position(x: 1, y: 2)
//        let name = Name(name: "Hello")
//        let vel = Velocity(a: 1.234)
//
//        let entity = nexus.createEntity()
//        entity.assign(pos)
//        entity.assign(name, vel)
//
//        let expectedComponents: [Component] = [pos, name, vel]
//        let allComponents = Array(entity.makeComponentsIterator())
//
//        XCTAssertTrue(allComponents.elementsEqualUnordered(expectedComponents) { $0 == $1 })
//    }

    func testEntityEquality() {
        let nexus = Nexus()

        let entityA = nexus.createEntity()
        let entityB = nexus.createEntity()

        XCTAssertEqual(entityA, entityA)
        XCTAssertNotEqual(entityA, entityB)
    }

    func testRemoveAllComponentsFromEntity() {
        let nexus = Nexus()

        let entity = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "MyEntity"))
        XCTAssertEqual(entity.numComponents, 2)
        entity.removeAll()
        XCTAssertEqual(entity.numComponents, 0)
    }

    func testEntityIdGenerator() {
        let generator = DefaultEntityIdGenerator()

        XCTAssertEqual(generator.count, 1)

        for _ in 0..<100 {
            _ = generator.nextId()
        }

        XCTAssertEqual(generator.count, 1)

        for i in 10..<60 {
            generator.markUnused(entityId: EntityIdentifier(UInt32(i)))
        }

        XCTAssertEqual(generator.count, 51)

        for _ in 0..<50 {
            _ = generator.nextId()
        }

        XCTAssertEqual(generator.count, 1)
    }

    func testEntitySubscripts() {
        let nexus = Nexus()
        let pos = Position(x: 12, y: 45)
        let name = Name(name: "SomeName")
        let entity = nexus.createEntity(with: pos, name)

        XCTAssertEqual(entity[\Position.x], 12)
        XCTAssertEqual(entity[\Position.y], 45)
        XCTAssertEqual(entity[\Name.name], "SomeName")

        entity[\Position.x] = 67
        entity[\Position.y] = 89
        entity[\Name.name] = "AnotherName"

        XCTAssertEqual(entity[\Position.x], 67)
        XCTAssertEqual(entity[\Position.y], 89)
        XCTAssertEqual(entity[\Name.name], "AnotherName")

        entity[\Velocity.a] = 123
        XCTAssertEqual(entity[\Velocity.a], 123.0)

        entity[Position.self]?.x = 1234
        XCTAssertEqual(entity[Position.self]?.x, 1234)
        XCTAssertEqual(entity[Velocity.self]?.a, 123.0)

        // remove position component
        entity[Position.self] = nil
        XCTAssertNil(entity[Position.self])
        entity[Position.self] = pos // assign position comp instance
        XCTAssertTrue(entity[Position.self] === pos)
        entity[Position.self] = pos // re-assign
        XCTAssertTrue(entity[Position.self] === pos)
        entity[Position.self] = nil // remove position component
        XCTAssertNil(entity[Position.self])

        let opts = Optionals(1, 2, "hello")
        entity[Optionals.self] = opts
        XCTAssertEqual(entity[Optionals.self], opts)

        entity[\Optionals.float] = nil
        XCTAssertEqual(entity[\Optionals.float], nil)
        XCTAssertEqual(entity[\Optionals.int], 1)
        XCTAssertEqual(entity[\Optionals.string], "hello")

        entity[Optionals.self] = nil
        XCTAssertNil(entity[Optionals.self])
        entity[\Optionals.string] = "world"
        XCTAssertEqual(entity[\Optionals.string], "world")

        entity.assign(Comp1(12))
        XCTAssertEqual(entity[\Comp1.value], 12)
    }

    func testComponentsIteration() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        XCTAssertTrue(Array(entity.makeComponentsIterator()).isEmpty)
        entity.assign(Position())
        XCTAssertEqual(Array(entity.makeComponentsIterator()).count, 1)
    }

    func testEntityCreationIntrinsic() {
        let nexus = Nexus()
        let entity = nexus.createEntity()

        let secondEntity = entity.createEntity()
        XCTAssertNotEqual(secondEntity, entity)

        let thirdEntity = secondEntity.createEntity()
        XCTAssertNotEqual(secondEntity, thirdEntity)
        XCTAssertNotEqual(entity, thirdEntity)

        let entityWithComponents = entity.createEntity(with: Position(), Name())
        XCTAssertTrue(entityWithComponents.has(Position.self))
        XCTAssertTrue(entityWithComponents.has(Name.self))

        XCTAssertEqual(nexus.numEntities, 4)
        XCTAssertEqual(nexus.numComponents, 2)
    }

    func testEntityDescriptions() {
        let nexus = Nexus()
        let entt = nexus.createEntity()
        XCTAssertFalse(entt.description.isEmpty)
        XCTAssertFalse(entt.debugDescription.isEmpty)
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
