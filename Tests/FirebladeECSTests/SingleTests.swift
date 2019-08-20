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
        let single = nexus.single(SingleGameState.self)
        XCTAssertEqual(single.nexus, self.nexus)
        XCTAssertTrue(single.nexus === self.nexus)
        XCTAssertEqual(single.traits.requiresAll.count, 1)
        XCTAssertEqual(single.traits.excludesAll.count, 0)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        let traits = FamilyTraitSet(requiresAll: [SingleGameState.self], excludesAll: [])
        XCTAssertEqual(single.traits, traits)
    }
    
    func testSingleReuse() {
        let singleA = nexus.single(SingleGameState.self)
        
        let singleB = nexus.single(SingleGameState.self)
        
        XCTAssertEqual(nexus.familyMembersByTraits.keys.count, 1)
        XCTAssertEqual(nexus.familyMembersByTraits.values.count, 1)
        
        XCTAssertEqual(singleA, singleB)
    }
    
    
    func testSingleEntityAndComponentCreation() {
        let single = nexus.single(SingleGameState.self)
        let gameState = SingleGameState()
        XCTAssertNotNil(single.entity)
        XCTAssertNotNil(single.component)
        XCTAssertEqual(single.component.shouldQuit, gameState.shouldQuit)
        XCTAssertEqual(single.component.playerHealth, gameState.playerHealth)
        
    }
    
    func testSingleCreationOnExistingFamilyMember() {
        _ = nexus.createEntity(with: Position(x: 1, y: 2))
        let singleGame = SingleGameState()
        _ = nexus.createEntity(with: singleGame)
        let single = nexus.single(SingleGameState.self)
        XCTAssertTrue(singleGame === single.component)
    }
}
