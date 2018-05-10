//
//  FamilyPerformanceTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.05.18.
//

import XCTest
import FirebladeECS

class FamilyPerformanceTests: XCTestCase {
    
    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }
    
    override func tearDown() {
        nexus = nil
        super.tearDown()
    }
    
    
    func testMeasureIterateMembers() {
        
        let number: Int = 10_000
        
        for i in 0..<number {
            nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
        }
        
        let family = nexus.family(requiresAll: [Position.self, Velocity.self],
                                  excludesAll: [Party.self],
                                  needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        XCTAssertEqual(family.count, number)
        XCTAssertEqual(nexus.numEntities, number)
        
        measure {
            family.iterate { (entityId: EntityIdentifier) in
                _ = entityId
            }
        }
    }
    
    func testMeasureFamilyIterationOne() {
        
        let number: Int = 10_000
        
        for i in 0..<number {
            nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
        }
        
        let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        XCTAssert(family.count == number)
        XCTAssert(nexus.numEntities    == number)
        
        measure {
            family.iterate { (velocity: Velocity!) in
                _ = velocity
            }
        }
        
    }
    func testMeasureFamilyIterationThree() {
        
        let number: Int = 10_000
        
        for i in 0..<number {
            nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
        }
        
        let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        XCTAssert(family.count == number)
        XCTAssert(nexus.numEntities == number)
        
        measure {
            family.iterate { (entity: Entity!, position: Position!, velocity: Velocity!, name: Name?) in
                position.x += entity.identifier.index
                _ = velocity
                _ = name
            }
        }
        
    }
    
    
    
}
