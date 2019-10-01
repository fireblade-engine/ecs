//
//  FamilyTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

@testable import FirebladeECS
import XCTest

class FamilyTests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    override func tearDown() {
        nexus = nil
        super.tearDown()
    }

    func createDefaultEntity() {
        let e = nexus.createEntity()
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }

    func testFamilyCreation() {
        let family = nexus.family(requires: Position.self,
                                  excludesAll: Name.self)

        XCTAssertEqual(family.nexus, self.nexus)
        XCTAssertTrue(family.nexus === self.nexus)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 0)

        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [Name.self])
        XCTAssertEqual(family.traits, traits)
    }

    func testFamilyReuse() {
        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)

        let familyB = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)

        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)

        XCTAssertEqual(familyA, familyB)
    }

    func testFamilyAbandoned() {
        XCTAssertEqual(nexus.numFamilies, 0)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 0)
        _ = nexus.family(requires: Position.self)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 0)
        let entity = nexus.createEntity()
        XCTAssertFalse(entity.has(Position.self))
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 1)
        entity.assign(Position(x: 1, y: 1))
        XCTAssertTrue(entity.has(Position.self))
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        entity.remove(Position.self)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 1)
        nexus.destroy(entity: entity)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 0)
        XCTAssertEqual(nexus.numEntities, 0)
    }

    func testFamilyLateMember() {
        let eEarly = nexus.createEntity(with: Position(x: 1, y: 2))
        XCTAssertEqual(nexus.numFamilies, 0)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        let family = nexus.family(requires: Position.self)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        let eLate = nexus.createEntity(with: Position(x: 1, y: 2))
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, 2)
        XCTAssertEqual(nexus.numEntities, 2)
        XCTAssertTrue(family.isMember(eEarly))
        XCTAssertTrue(family.isMember(eLate))
    }

    func testFamilyExchange() {
        let number: Int = 10

        for i in 0..<number {
            nexus.createEntity(with: Position(x: i + 1, y: i + 2))
        }

        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Velocity.self)

        let familyB = nexus.family(requires: Velocity.self,
                                   excludesAll: Position.self)

        XCTAssertEqual(familyA.count, 10)
        XCTAssertEqual(familyB.count, 0)

        familyA
            .entityAndComponents
            .forEach { (entity: Entity, _: Position) in
                entity.assign(Velocity(a: 3.14))
                entity.remove(Position.self)
        }

        XCTAssertEqual(familyA.count, 0)
        XCTAssertEqual(familyB.count, 10)

        familyB
            .entityAndComponents
            .forEach { (entity: Entity, velocity: Velocity) in
                entity.assign(Position(x: 1, y: 2))
                entity.remove(velocity)
        }

        XCTAssertEqual(familyA.count, 10)
        XCTAssertEqual(familyB.count, 0)
    }

    func testFamilyMemberBasicIteration() {
        for i in 0..<1000 {
            nexus.createEntity(with: Position(x: i + 1, y: i + 2))
            nexus.createEntity(with: Velocity(a: Float(i)))
        }

        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Velocity.self)

        let familyB = nexus.family(requires: Velocity.self,
                                   excludesAll: Position.self)

        familyA.forEach { (pos: Position?) in
            XCTAssertNotNil(pos)
        }

        familyB.forEach { (vel: Velocity?) in
            XCTAssertNotNil(vel)
        }
    }

    func testFamilyBulkDestroy() {
        let count = 10_000

        for _ in 0..<count {
            createDefaultEntity()
        }

        let family = nexus.family(requires: Position.self)

        XCTAssertEqual(family.memberIds.count, count)

        let currentCount: Int = (count / 2)

        family
            .entities
            .prefix(currentCount)
            .forEach { (entity: Entity) in
                entity.destroy()
        }

        XCTAssertEqual(family.memberIds.count, (count / 2))

        for _ in 0..<count {
            createDefaultEntity()
        }

        XCTAssertEqual(family.memberIds.count, count + (count / 2))
    }
}
