//
//  EntityTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 22.10.17.
//

import FirebladeECS
import XCTest

class EntityTests: XCTestCase {
    func testEntityIdentifierAndIndex() {
        let min = EntityIdentifier(.min)
        XCTAssertEqual(min.index, Int(UInt32.min))

        let uRand = UInt32.random(in: UInt32.min...UInt32.max)
        let rand = EntityIdentifier(uRand)
        XCTAssertEqual(rand.index, Int(uRand))

        let max = EntityIdentifier(.max)
        XCTAssertEqual(max, EntityIdentifier.invalid)
        XCTAssertEqual(max.index, Int(UInt32.max))
    }
    
    func testEntityIdentifierComparison() {
        XCTAssertTrue(EntityIdentifier(1) < EntityIdentifier(2))
        XCTAssertTrue(EntityIdentifier(23) > EntityIdentifier(4))
    }
}
