//
//  ComponentTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 21.10.17.
//

import FirebladeECS
import XCTest

class ComponentTests: XCTestCase {

	func testComponentIdentifier() {
		XCTAssertEqual(Position.identifier, Position.identifier)
		XCTAssertEqual(Velocity.identifier, Velocity.identifier)
        XCTAssertNotEqual(Velocity.identifier, Position.identifier)
        
        let p1 = Position(x: 1, y: 2)
        let v1 = Velocity(a: 3.14)
        XCTAssertEqual(p1.identifier, Position.identifier)
        XCTAssertEqual(v1.identifier, Velocity.identifier)
        XCTAssertNotEqual(v1.identifier, p1.identifier)
                
	}


}
