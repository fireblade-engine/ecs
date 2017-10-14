//
//  NexusTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import XCTest
@testable import FirebladeECS

class NexusTests: XCTestCase {

	let nexus = Nexus()

	func testNexus() {

		let e0 = nexus.create(entity: "E0")
		XCTAssert(e0.identifier == 0)
		XCTAssert(e0.identifier.index == 0)

		let p0 = Position(x: 1, y: 2)
		let n0 = Name(name: "FirstName")

		e0.add(p0)
		e0.add(n0)

		let rE1 = nexus.get(entity: e0.identifier)

		let rN0: Name = rE1!.component(Name.self)
		let rP0: Position = rE1!.component(Position.self)


		XCTAssert(rN0.name == "FirstName")
		XCTAssert(rP0.x == 1)
		XCTAssert(rP0.y == 2)

		let count = nexus.count(components: rE1!.identifier)

		XCTAssert(count == 2)

	}


}
