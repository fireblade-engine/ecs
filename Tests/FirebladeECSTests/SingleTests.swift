//
//  SingleTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 13.02.19.
//


@testable import FirebladeECS
import XCTest

class SingleTests: XCTestCase {
    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }
    
    override func tearDown() {
        nexus = nil
        super.tearDown()
    }
    
    func testSingleCreation() {
        let single = nexus.single(requires: Position.self,
                                  excludesAll: Name.self)
        XCTAssertEqual(single.nexus, self.nexus)
        XCTAssertTrue(single.nexus === self.nexus)
        XCTAssertEqual(single.traits.requiresAll.count, 1)
        XCTAssertEqual(single.traits.excludesAll.count, 1)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [Name.self])
        XCTAssertEqual(single.traits, traits)
    }
    
    func testSingleReuse() {
        let singleA = nexus.single(requires: Position.self,
                                   excludesAll: Name.self)
        
        let singleB = nexus.single(requires: Position.self,
                                   excludesAll: Name.self)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        XCTAssertEqual(singleA, singleB)
    }
    
    
    func testSingleEntityAndComponentCreation() {
        let single = nexus.single(requires: Position.self,
                                  excludesAll: Name.self)
        XCTAssertNil(single.entity)
        XCTAssertNil(single.component)
        let pos = Position(x: 1, y: 2)
        nexus.create(with: pos)
        XCTAssertNotNil(single.entity)
        XCTAssertNotNil(single.component)
        XCTAssertEqual(single.component?.x, pos.x)
        XCTAssertEqual(single.component?.y, pos.y)
        
    }
}
