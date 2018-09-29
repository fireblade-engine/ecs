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
        let family = nexus.family(requires: Position.self)
        
        family
            .entities
            .prefix(count)
            .forEach { (entity: Entity) in
                entity.destroy()
        }
    }
    
}

class ColorSystem {
    
    let nexus: Nexus
    lazy var colors = nexus.family(requires: Color.self)
    
    init(nexus: Nexus) {
        self.nexus = nexus
    }
    
    func update() {
        colors
            .forEach { (color: Color) in
                color.r = 1
                color.g = 2
                color.b = 3
        }
    }
}

class PositionSystem {
    let positions: TypedFamily1<Position>
    
    var velocity: Double = 4.0
    
    init(nexus: Nexus) {
        positions = nexus.family(requires: Position.self)
    }
    
    func randNorm() -> Double {
        return 4.0
    }
    
    func update() {
        positions
            .forEach { [unowned self](pos: Position) in
            
            let deltaX: Double = self.velocity * ((self.randNorm() * 2) - 1)
            let deltaY: Double = self.velocity * ((self.randNorm() * 2) - 1)
            let x = pos.x + Int(deltaX)
            let y = pos.y + Int(deltaY)
            
            pos.x = x
            pos.y = y
        }
    }
    
}
