//
//  FamilyTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import XCTest
/*@testable */import FirebladeECS

class FamilyTests: XCTestCase {

	let entityHub: EntityHub = EntityHub()

	func testFamily() {

		let e1 = entityHub.createEntity()
		e1 += EmptyComponent()
		let e2 = entityHub.createEntity()
		e2 += EmptyComponent()

		let traits = FamilyTraits(hasAll: [EmptyComponent.uct], hasAny: [], hasNone: [])

		let (new, _) = entityHub.family(with: traits)
		XCTAssert(new == true)

		let (new2, _) = entityHub.family(with: traits)
		XCTAssert(new2 == false)

		let e3 = entityHub.createEntity()
		e3 += EmptyComponent()

		e2.remove(EmptyComponent.self)

	}
}
