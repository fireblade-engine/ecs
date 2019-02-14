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

		let min: EntityIndex = EntityIdentifier(EntityIdentifier.min).index
		XCTAssert(EntityIndex(min).identifier == min)

		let rand: EntityIndex = EntityIdentifier(EntityIdentifier(arc4random())).index
		XCTAssert(EntityIndex(rand).identifier == rand)

		let max: EntityIndex = EntityIdentifier(EntityIdentifier.max).index
		XCTAssert(EntityIndex(max).identifier == max)

	}

}
