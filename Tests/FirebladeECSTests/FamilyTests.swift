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
		e1 += Name(name: "Sarah")

		let (empty, name) =  e1.components(EmptyComponent.self, Name.self)

		print(empty, name)

		e1.components { (empty: EmptyComponent, name: Name) in
			print(empty, name)
		}

		let traits = FamilyTraits(hasAll: [EmptyComponent.uct], hasAny: [], hasNone: [])

		let (new, family) = entityHub.family(with: traits)
		XCTAssert(new == true)

		let (new2, _) = entityHub.family(with: traits)
		XCTAssert(new2 == false)

		let e3 = entityHub.createEntity()
		e3 += EmptyComponent()
		e3 += Name(name: "Michael")

		e2.remove(EmptyComponent.self)

		family.components { (name: Name, empty: EmptyComponent) in
			print(name, empty)
		}
	}
}
