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
		let p1 = Position(x: 1, y: 2)
		XCTAssert(p1.identifier == Position.identifier)

		let v1 = Velocity(a: 3.14)
		XCTAssert(v1.identifier == Velocity.identifier)
		XCTAssert(v1.identifier != p1.identifier)
		XCTAssert(Velocity.identifier != Position.identifier)
	}


}
