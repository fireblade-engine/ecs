//
//  FamilyTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

@testable import FirebladeECS
import XCTest

class FamilyTests: XCTestCase {

	func testFamilyCreation() {
		let nexus = Nexus()

		let family: Family = nexus.family(requiresAll: [Position.self],
										  excludesAll: [Name.self],
										  needsAtLeastOne: [Velocity.self])
		_ = family
	}

	func testTraitCommutativity() {

		let t1 = FamilyTraitSet(requiresAll: [Position.self, Velocity.self], excludesAll: [Name.self], needsAtLeastOne: [])
		let t2 = FamilyTraitSet(requiresAll: [Velocity.self, Position.self], excludesAll: [Name.self], needsAtLeastOne: [])

		XCTAssert(t1 == t2)
		XCTAssert(t1.hashValue == t2.hashValue)

	}

	func testTraitMatching() {
		let nexus = Nexus()
		let a = nexus.create(entity: "a")
		a.assign(Position(x: 1, y: 2))
		a.assign(Name(name: "myName"))
		a.assign(Velocity(a: 3.14))
		a.assign(EmptyComponent())

		let noMatch = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Name.self])
		let isMatch = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [], needsAtLeastOne: [Name.self, EmptyComponent.self])

		XCTAssertFalse(noMatch.canBecomeMember(a))
		XCTAssertTrue(isMatch.canBecomeMember(a))

	}

	func testMeasureTraitMatching() {
		let nexus = Nexus()
		let a = nexus.create(entity: "a")
		a.assign(Position(x: 1, y: 2))
		a.assign(Name(name: "myName"))
		a.assign(Velocity(a: 3.14))
		a.assign(EmptyComponent())

		let isMatch = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		measure {
			for _ in 0..<10_000 {
				let success = isMatch.canBecomeMember(a)
				XCTAssert(success)
			}
		}
	}

	func testMeasureIterateMembers() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		XCTAssert(family.count == number)
		XCTAssert(nexus.numEntities == number)

		measure {
			family.iterate(entities: { entityId in
				_ = entityId
			})
		}
	}

	func testMeasureFamilyIterationOne() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		XCTAssert(family.count == number)
		XCTAssert(nexus.numEntities	== number)

		measure {
			family.iterate(components: Velocity.self) { (_, vel) in
				let velocity: Velocity = vel!
				_ = velocity
			}
		}

	}
	func testMeasureFamilyIterationThree() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1 + i, y: 2 + i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		XCTAssert(family.count == number)
		XCTAssert(nexus.numEntities == number)

		measure {
			family.iterate(components: Position.self, Velocity.self, Name.self) { entityId, pos, vel, nm in
				let position: Position = pos!
				let velocity: Velocity = vel!
				let name: Name? = nm

				position.x += entityId.index
				_ = velocity
				_ = name
			}
		}

	}

	func testFamilyExchange() {
		let nexus = Nexus()
		let number: Int = 10

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
		}

		let familyA = nexus.family(requiresAll: [Position.self], excludesAll: [Velocity.self])
		let familyB = nexus.family(requiresAll: [Velocity.self], excludesAll: [Position.self])

		var countA: Int = 0
		familyA.iterate(components: Position.self) { (entityId, _) in
			let e = nexus.get(entity: entityId)!
			e.assign(Velocity(a: 3.14))
			e.remove(Position.self)
			countA += 1
		}
		XCTAssert(countA == number)

		var countB: Int = 0
		familyB.iterate(components: Velocity.self) { eId, velocity in
			let e = nexus.get(entity: eId)!
			e.assign(Position(x: 1, y: 2))
			e.remove(velocity!)
			countB += 1
		}
		XCTAssert(countB == number)

	}


	func testIterationSimple() {
		let nexus = Nexus()

		for i in 0..<1000 {
			nexus.create(entity: "\(i)").assign(Position(x: i + 1, y: i + 2))
		}

		let familyA = nexus.family(requiresAll: [Position.self], excludesAll: [Velocity.self])
		let familyB = nexus.family(requiresAll: [Velocity.self], excludesAll: [Position.self])

		familyA.iterate { (_: EntityIdentifier, pos: Position!, vel: Velocity!) in

		}

		
	}



}



