//
//  FamilyPerformanceTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.05.18.
//

import FirebladeECS
import XCTest

class FamilyPerformanceTests: XCTestCase {
    
    let numEntities: Int = 10_000
    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
        
        for i in 0..<numEntities {
            nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i),
                                                Name(name: "myName\(i)"),
                                                Velocity(a: 3.14),
                                                EmptyComponent(),
                                                Color())
        }
    }
    
    override func tearDown() {
        nexus = nil
        super.tearDown()
    }
    
    func testMeasureIterateMembers() {
        
        let family = nexus.family(requiresAll: [Position.self, Velocity.self],
                                  excludesAll: [Party.self],
                                  needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (entityId: EntityIdentifier) in
                _ = entityId
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testMeasureFamilyIterationOne() {
        let family = nexus.family(requiresAll: [Position.self], excludesAll: [Party.self])
        
        XCTAssert(family.count == numEntities)
        XCTAssert(nexus.numEntities == numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (velocity: Velocity!) in
                _ = velocity
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testMeasureFamilyIterationTwo() {
        let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self])
        
        XCTAssert(family.count == numEntities)
        XCTAssert(nexus.numEntities == numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (position: Position!, velocity: Velocity!) in
                _ = velocity
                _ = position
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
        
    }
    
    func testMeasureFamilyIterationThree() {
        let family = nexus.family(requiresAll: [Position.self, Velocity.self, Name.self], excludesAll: [Party.self])
        
        XCTAssert(family.count == numEntities)
        XCTAssert(nexus.numEntities == numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (position: Position!, velocity: Velocity!, name: Name!) in
                _ = position
                _ = velocity
                _ = name
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testMeasureFamilyIterationFour() {
        let family = nexus.family(requiresAll: [Position.self, Velocity.self, Name.self, Color.self], excludesAll: [Party.self])
        
        XCTAssert(family.count == numEntities)
        XCTAssert(nexus.numEntities == numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (position: Position!, velocity: Velocity!, name: Name!, color: Color!) in
                _ = position
                _ = velocity
                _ = name
                _ = color
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testMeasureFamilyIterationFive() {
        let family = nexus.family(requiresAll: [Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self], excludesAll: [Party.self])
        
        XCTAssert(family.count == numEntities)
        XCTAssert(nexus.numEntities == numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.iterate { (position: Position!, velocity: Velocity!, name: Name!, color: Color!, empty: EmptyComponent!) in
                _ = position
                _ = velocity
                _ = name
                _ = color
                _ = empty
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
}
