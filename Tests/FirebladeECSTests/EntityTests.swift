//
//  EntityTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 22.10.17.
//

import XCTest
import FirebladeECS

class EntityTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

	func testEntityIdentifierAndIndex() {

		let min: EntityIndex = EntityIdentifier(EntityIdentifier.min).index
		XCTAssert(EntityIndex(min).identifier == min)

		let rand: EntityIndex = EntityIdentifier(EntityIdentifier(arc4random())).index
		XCTAssert(EntityIndex(rand).identifier == rand)

		let max: EntityIndex = EntityIdentifier(EntityIdentifier.max).index
		XCTAssert(EntityIndex(max).identifier == max)

	}

}
