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
        XCTAssertEqual(min.id, Int(UInt32.min))

        let uRand = UInt32.random(in: UInt32.min...UInt32.max)
        let rand = EntityIdentifier(uRand)
        XCTAssertEqual(rand.id, Int(uRand))

        let max = EntityIdentifier(.max)
        XCTAssertEqual(max, EntityIdentifier.invalid)
        XCTAssertEqual(max.id, Int(UInt32.max))
    }

    func testAllComponentsOfEntity() {
        let nexus = Nexus()

        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Hello")
        let vel = Velocity(a: 1.234)

        let entity = nexus.createEntity()
        entity.assign(pos)
        entity.assign(name, vel)

        let expectedComponents: [Component] = [pos, name, vel]
        let allComponents = entity.allComponents()

        XCTAssertTrue(allComponents.elementsEqualUnordered(expectedComponents) { $0 === $1 })
    }

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
        let generator = EntityIdentifierGenerator()

        XCTAssertEqual(generator.count, 1)

        for _ in 0..<100 {
            _ = generator.nextId()
        }

        XCTAssertEqual(generator.count, 1)

        for i in 10..<60 {
            generator.freeId(EntityIdentifier(UInt32(i)))
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
        XCTAssertNil(entity[\Velocity.a])

        entity[Position.self]?.x = 1234
        XCTAssertEqual(entity[Position.self]?.x, 1234)
        XCTAssertNil(entity[Velocity.self]?.a)
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
