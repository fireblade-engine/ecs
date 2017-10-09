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

		let traits = FamilyTraits(hasAll: [EmptyComponent.uct], hasAny: [], hasNone: [])

		let simpleFamily = entityHub.createFamily(with: traits)

		let e = entityHub.createEntity()
		e += EmptyComponent()

		e.remove(EmptyComponent.self)

	}
}
