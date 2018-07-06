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

        let posTraits = positionSystem.family.traits

        XCTAssertEqual(nexus.numEntities, 0)
        XCTAssertEqual(colorSystem.family.memberIds.count, 0)
        XCTAssertEqual(positionSystem.family.memberIds.count, 0)
        XCTAssertEqual(nexus.freeEntities.count, 0)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, 0)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(colorSystem.family.memberIds.count, num)
        XCTAssertEqual(positionSystem.family.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(colorSystem.family.memberIds.count, num)
        XCTAssertEqual(positionSystem.family.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(colorSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(colorSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)

        batchDestroyEntities(count: num)

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(nexus.freeEntities.count, num)
        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(colorSystem.family.memberIds.count, num)
        XCTAssertEqual(positionSystem.family.memberIds.count, num)

        colorSystem.update()
        positionSystem.update()

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num)
        XCTAssertEqual(nexus.numEntities, num)
        XCTAssertEqual(colorSystem.family.memberIds.count, num)
        XCTAssertEqual(positionSystem.family.memberIds.count, num)
        XCTAssertEqual(nexus.freeEntities.count, num)

        batchCreateEntities(count: num)

        XCTAssertEqual(nexus.familyMembersByTraits[posTraits]?.count, num * 2)
        XCTAssertEqual(nexus.numEntities, num * 2)
        XCTAssertEqual(colorSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(positionSystem.family.memberIds.count, num * 2)
        XCTAssertEqual(nexus.freeEntities.count, 0)
    }

    func createDefaultEntity(name: String?) {
        let e = nexus.create(entity: name)
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }

    func batchCreateEntities(count: Int) {
        for _ in 0..<count {
            createDefaultEntity(name: nil)
        }
    }

    func batchDestroyEntities(count: Int) {
        let family = nexus.family(requiresAll: [Position.self], excludesAll: [])
        var currentCount = count

        family.iterate { (entity: Entity!) in
            if currentCount > 0 {
                entity.destroy()
                currentCount -= 1
            } else {
                // FIXME: this is highly inefficient since we can not break out of the iteration
                return
            }
        }

    }

}

class ColorSystem {

    let family: Family

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: [Color.self], excludesAll: [])
    }

    func update() {
        family.iterate { (color: Color!) in
            color.r = 1
            color.g = 2
            color.b = 3
        }
    }
}

class PositionSystem {
    let family: Family

    var velocity: Double = 4.0

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: [Position.self],
                              excludesAll: [])
    }

    func randNorm() -> Double {
        return 4.0
    }

    func update() {
        family.iterate { [unowned self](pos: Position!) in

            let deltaX: Double = self.velocity * ((self.randNorm() * 2) - 1)
            let deltaY: Double = self.velocity * ((self.randNorm() * 2) - 1)
            let x = pos.x + Int(deltaX)
            let y = pos.y + Int(deltaY)

            pos.x = x
            pos.y = y
        }
    }

}
