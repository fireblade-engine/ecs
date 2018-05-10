//
//  FamilyTraitsTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.05.18.
//

import XCTest
@testable import FirebladeECS

class FamilyTraitsTests: XCTestCase {
    
    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }
    
    override func tearDown() {
        nexus = nil
        super.tearDown()
    }
    
   
    func testTraitCommutativity() {
        
        let t1 = FamilyTraitSet(requiresAll: [Position.self, Velocity.self],
                                excludesAll: [Name.self],
                                needsAtLeastOne: [])
        let t2 = FamilyTraitSet(requiresAll: [Velocity.self, Position.self],
                                excludesAll: [Name.self],
                                needsAtLeastOne: [])
        
        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1.hashValue, t2.hashValue)
        
    }
    
    func testTraitMatching() {
        
        let a = nexus.create(entity: "a")
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())
        
        let noMatch = nexus.family(requiresAll: [Position.self, Velocity.self],
                                   excludesAll: [Name.self])
        
        let isMatch = nexus.family(requiresAll: [Position.self, Velocity.self],
                                   excludesAll: [],
                                   needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        XCTAssertFalse(noMatch.canBecomeMember(a))
        XCTAssertTrue(isMatch.canBecomeMember(a))
        
    }
    
    func testMeasureTraitMatching() {
        
        let a = nexus.create(entity: "a")
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())
        
        let isMatch = nexus.family(requiresAll: [Position.self, Velocity.self],
                                   excludesAll: [Party.self],
                                   needsAtLeastOne: [Name.self, EmptyComponent.self])
        
        measure {
            for _ in 0..<10_000 {
                let success = isMatch.canBecomeMember(a)
                XCTAssert(success)
            }
        }
    }
    
}
