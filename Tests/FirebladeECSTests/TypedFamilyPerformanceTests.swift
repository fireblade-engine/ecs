//
//  TypedFamilyPerformanceTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

import FirebladeECS
import XCTest

class TypedFamilyPerformanceTests: XCTestCase {
    
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
    
    func testPerformanceTypedFamilyOneComponent() {
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.members.forEach { (position: Position) in
                _ = position
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testPerformanceTypedFamilyTwoComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.members.forEach { (position: Position, velocity: Velocity) in
                _ = position
                _ = velocity
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testPerformanceTypedFamilyThreeComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.members.forEach { (position: Position, velocity: Velocity, name: Name) in
                _ = position
                _ = velocity
                _ = name
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testPerformanceTypedFamilyFourComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, excludesAll: Party.self)
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.members.forEach { (position: Position, velocity: Velocity, name: Name, color: Color) in
                _ = position
                _ = velocity
                _ = name
                _ = color
                
                loopCount += 1
            }
        }
        
        XCTAssertEqual(loopCount, family.count * 10)
    }
    
    func testPerformanceTypedFamilyFiveComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self, excludesAll: Party.self)
        
        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        
        var loopCount: Int = 0
        
        measure {
            family.members.forEach { (position: Position, velocity: Velocity, name: Name, color: Color, empty: EmptyComponent) in
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
