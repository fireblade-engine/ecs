//
//  FamilyTraitsTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.05.18.
//

import FirebladeECS
import XCTest

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
                                excludesAll: [Name.self])
        let t2 = FamilyTraitSet(requiresAll: [Velocity.self, Position.self],
                                excludesAll: [Name.self])

        XCTAssertEqual(t1, t2)
        XCTAssertEqual(t1.hashValue, t2.hashValue)

    }

    func testTraitMatching() {

        let a = nexus.createEntity()
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())

        let noMatch = nexus.family(requiresAll: Position.self, Velocity.self,
                                   excludesAll: Name.self)

        let isMatch = nexus.family(requiresAll: Position.self, Velocity.self)

        XCTAssertFalse(noMatch.canBecomeMember(a))
        XCTAssertTrue(isMatch.canBecomeMember(a))

    }

}
