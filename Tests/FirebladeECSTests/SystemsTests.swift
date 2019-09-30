//
//  SystemsTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 10.05.18.
//

@testable import FirebladeECS
import XCTest

class SystemsTests: XCTestCase {
    var nexus: Nexus!
    var colorSystem: ColorSystem!
    var positionSystem: PositionSystem!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
        colorSystem = ColorSystem(nexus: nexus)
        positionSystem = PositionSystem(nexus: nexus)
    }

    override func tearDown() {
        colorSystem = nil
        positionSystem = nil
        nexus = nil
        super.tearDown()
    }

    func testSystemsUpdate() {
        let num: Int = 10_000

        colorSystem.update()
        positionSystem.update()

        let posTraits = positionSystem.positions.traits

        XCTAssertEqual(nexus.numEntities, 0)
        XCTAssertEqual(colorSystem.colors.memberIds.count, 0)
        XCTAssertEqual(positionSystem.positions.memberIds.count, 0)
        XCTAssertEqual(nexus.freeEntities.count, 0)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, 0)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        batchDestroyEntities(count: num)

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(nexus.freeEntities.count, num)
        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, num)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(colorSystem.colors.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.positions.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)
    }

    func createDefaultEntity() {
        let e = nexus.createEntity()
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }

    func batchCreateEntities(count: Int) {
        for _ in 0..<count {
            createDefaultEntity()
        }
    }

    func batchDestroyEntities(count: Int) {
        let family = nexus.family(requires: Position.self)

        family
            .entities
            .prefix(count)
            .forEach { (entity: Entity) in
                entity.destroy()
            }
    }
}
