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
        
        let family: Family = nexus.family(requiresAll: [Position.self],
                                          excludesAll: [Name.self],
                                          needsAtLeastOne: [Velocity.self])
        
        XCTAssertEqual(family.nexus, self.nexus)
        XCTAssertTrue(family.nexus === self.nexus)
        XCTAssertEqual(nexus.familiesByTraitHash.count, 1)
        XCTAssertEqual(nexus.familiesByTraitHash.values.first!, family)
        
        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [Name.self], needsAtLeastOne: [Velocity.self])
        XCTAssertEqual(family.traits, traits)
    }
    
    func testFamilyReuse() {
        
        let familyA: Family = nexus.family(requiresAll: [Position.self],
                                           excludesAll: [Name.self],
                                           needsAtLeastOne: [Velocity.self])
        
        let familyB: Family = nexus.family(requiresAll: [Position.self],
                                           excludesAll: [Name.self],
                                           needsAtLeastOne: [Velocity.self])
        
        XCTAssertEqual(nexus.familiesByTraitHash.count, 1)
        XCTAssertEqual(familyA, familyB)
        XCTAssertTrue(familyA === familyB)
    }
    
    
    
    func testFamilyExchange() {
        
        let number: Int = 10
        
        for i in 0..<number {
            nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
        }
        
        let familyA = nexus.family(requiresAll: [Position.self],
                                   excludesAll: [Velocity.self])
        
        let familyB = nexus.family(requiresAll: [Velocity.self],
                                   excludesAll: [Position.self])
        
        var countA: Int = 0
        
        familyA.iterate { (entity: Entity!) in
            entity.assign(Velocity(a: 3.14))
            entity.remove(Position.self)
            countA += 1
        }
        
        XCTAssert(countA == number)
        
        var countB: Int = 0
        
        familyB.iterate { (entity: Entity!, velocity: Velocity!) in
            entity.assign(Position(x: 1, y: 2))
            entity.remove(velocity)
            countB += 1
        }
        
        XCTAssert(countB == number)
        
    }
    
    
    func testIterationSimple() {
        
        
        for i in 0..<1000 {
            nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
        }
        
        let familyA = nexus.family(requiresAll: [Position.self], excludesAll: [Velocity.self])
        _ = nexus.family(requiresAll: [Velocity.self], excludesAll: [Position.self])
        
        familyA.iterate { (pos: Position!, vel: Velocity!) in
            _ = pos
            _ = vel
        }
        
        
    }
    
    // MARK: - family performance
    
    
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
    
    
    
    // MARK: - family traits
    
    func testTraitCommutativity() {
        
        let t1 = FamilyTraitSet(requiresAll: [Position.self, Velocity.self], excludesAll: [Name.self], needsAtLeastOne: [])
        let t2 = FamilyTraitSet(requiresAll: [Velocity.self, Position.self], excludesAll: [Name.self], needsAtLeastOne: [])
        
        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1.hashValue, t2.hashValue)
        
    }
    
    func testTraitMatching() {
        
        let a = nexus.create(entity: "a")
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())
        
        let noMatch = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Name.self])
        let isMatch = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [], needsAtLeastOne: [Name.self, EmptyComponent.self])
        
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



