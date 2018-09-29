//
//  FamilyTests.swift
//  FirebladeECS
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
    
    func testFamilyCreation() {
        
        let family = nexus.family(requires: Position.self,
                                  excludesAll: Name.self)
        
        XCTAssertEqual(family.nexus, self.nexus)
        XCTAssertTrue(family.nexus === self.nexus)
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [Name.self])
        XCTAssertEqual(family.traits, traits)
    }
    
    func testFamilyReuse() {
        
        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)
        
        let familyB = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        XCTAssertEqual(familyA, familyB)
    }
    
    func testFamilyAbandoned() {
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 0)
        
        _ = nexus.family(requires: Position.self)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        
        let entity = nexus.create(entity: "eimer")
        entity.assign(Position(x: 1, y: 1))
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        
        entity.remove(Position.self)
        
        // FIXME: the family trait should vanish when no entity with revlevant component is present anymore
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        
        nexus.destroy(entity: entity)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        
    }
    
    func testFamilyLateMember() {
        
        let eEarly = nexus.create(entity: "eary").assign(Position(x: 1, y: 2))
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 0)
        
        let family = nexus.family(requires: Position.self)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        
        let eLate = nexus.create(entity: "late").assign(Position(x: 1, y: 2))
        
        //FIXME: XCTAssertTrue(family.isMember(eEarly))
        //FIXME: XCTAssertTrue(family.isMember(eLate))
        
    }
    
    func testFamilyExchange() {
        
        let number: Int = 10
        
        for i in 0..<number {
            nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
        }
        
        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Velocity.self)
        
        let familyB = nexus.family(requires: Velocity.self,
                                   excludesAll: Position.self)
        
        XCTAssertEqual(familyA.count, 10)
        XCTAssertEqual(familyB.count, 0)
        
        familyA
            .entityAndComponents
            .forEach { (entity: Entity, position: Position) in
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
            nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
            nexus.create(entity: "\(i)").assign(Velocity(a: Float(i)))
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
    
    func createDefaultEntity(name: String?) {
        let e = nexus.create(entity: name)
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }
    
    func testFamilyBulkDestroy() {
        let count = 10_000
        
        for _ in 0..<count {
            createDefaultEntity(name: nil)
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
            createDefaultEntity(name: nil)
        }
        
        XCTAssertEqual(family.memberIds.count, count + (count / 2))
    }
    
}
