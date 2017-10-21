//
//  NexusTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import Darwin.C.stdlib
import XCTest
@testable import FirebladeECS

class NexusTests: XCTestCase {

	override func setUp() {
		super.setUp()
	}

	override func tearDown() {
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

	func testCreateEntity() {
		let nexus: Nexus = Nexus()
		XCTAssert(nexus.count == 0)

		let e0 = nexus.create()
		XCTAssert(nexus.isValid(entity: e0))
		XCTAssert(nexus.count == 1)

		let e1 = nexus.create(entity: "Named e1")
		XCTAssert(nexus.isValid(entity: e1))
		XCTAssert(nexus.count == 2)

		XCTAssert(e0.name == nil)
		XCTAssert(e1.name == "Named e1")

		let rE0 = nexus.get(entity: e0.identifier)
		XCTAssert(rE0.name == e0.name)
		XCTAssert(rE0.identifier == e0.identifier)
	}

	func testDestroyAndReuseEntity() {
		let nexus: Nexus = Nexus()
		XCTAssert(nexus.count == 0)
		XCTAssert(nexus.freeEntities.count == 0)

		let e0 = nexus.create(entity: "e0")
		XCTAssert(nexus.isValid(entity: e0))
		XCTAssert(nexus.count == 1)

		let e1 = nexus.create(entity: "e1")
		XCTAssert(nexus.isValid(entity: e1))
		XCTAssert(nexus.count == 2)

		e0.destroy()

		XCTAssert(!nexus.isValid(entity: e0))
		XCTAssert(nexus.isValid(entity: e1))
		XCTAssert(nexus.count == 1)
		XCTAssert(nexus.freeEntities.count == 1)

		let e2 = nexus.create(entity: "e2")
		XCTAssert(!e0.isValid)
		XCTAssert(e1.isValid)
		XCTAssert(e2.isValid)

		XCTAssert(nexus.count == 2)
		XCTAssert(nexus.freeEntities.count == 0)

		XCTAssert(!(e0 == e2))
		XCTAssert(!(e0 === e2))
	}

	func testComponentCreation() {
		let nexus: Nexus = Nexus()
		XCTAssert(nexus.count == 0)
		XCTAssert(nexus.freeEntities.isEmpty)
		XCTAssert(nexus.componentsByType.isEmpty)

		let e0: Entity = nexus.create(entity: "e0")

		let p0 = Position(x: 1, y: 2)

		e0.assign(p0)

		XCTAssert(e0.isValid)
		XCTAssert(e0.hasComponents)
		XCTAssert(e0.numComponents == 1)

		let rP0: Position = e0.component(Position.self)!
		XCTAssert(rP0.x == 1)
		XCTAssert(rP0.y == 2)
	}

	func testComponentDeletion() {
		let nexus = Nexus()
		let identifier: EntityIdentifier = nexus.create(entity: "e0").identifier

		let e0 = nexus.get(entity: identifier)

		XCTAssert(e0.numComponents == 0)
		e0.remove(Position.self)
		XCTAssert(e0.numComponents == 0)

		let n0 = Name(name: "myName")
		let p0 = Position(x: 99, y: 111)

		e0.assign(n0)
		XCTAssert(e0.numComponents == 1)
		XCTAssert(e0.hasComponents)

		e0.remove(Name.self)

		XCTAssert(e0.numComponents == 0)
		XCTAssert(!e0.hasComponents)

		e0.assign(p0)

		XCTAssert(e0.numComponents == 1)
		XCTAssert(e0.hasComponents)

		e0.remove(p0)

		XCTAssert(e0.numComponents == 0)
		XCTAssert(!e0.hasComponents)

		e0.assign(n0)
		e0.assign(p0)

		XCTAssert(e0.numComponents == 2)
		let (name, position) = e0.components(Name.self, Position.self)

		XCTAssert(name.name == "myName")
		XCTAssert(position.x == 99)
		XCTAssert(position.y == 111)

		e0.destroy()

		XCTAssert(e0.numComponents == 0)
		XCTAssert(!e0.isValid)

	}

	func testComponentUniqueness() {
		let nexus = Nexus()
		let a = nexus.create()
		let b = nexus.create()
		let c = nexus.create()

		XCTAssert(nexus.count == 3)

		a.assign(Position(x: 0, y: 0))
		b.assign(Position(x: 0, y: 0))
		c.assign(Position(x: 0, y: 0))

		let pA: Position = a.component()!
		let pB: Position = b.component()!

		pA.x = 23
		pA.y = 32

		XCTAssert(pB.x != pA.x)
		XCTAssert(pB.y != pA.y)

	}

	func testComponentStorage() {
		let nexus = Nexus()
		let a = nexus.create()
		let b = nexus.create()
		let c = nexus.create()

	}

}
