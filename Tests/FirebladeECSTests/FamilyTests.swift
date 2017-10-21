//
//  FamilyTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import XCTest
@testable import FirebladeECS

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
			for _ in 0..<1_000_000 {
				let success = isMatch.canBecomeMember(a)
				XCTAssert(success)
			}
		}
	}

	func testIterateFamilyMembers() {

		let nexus = Nexus()

		let a = nexus.create(entity: "a").assign(Position(x: 1, y: 2), Name(name: "myName"), Velocity(a: 3.14), EmptyComponent())
		let b = nexus.create(entity: "b").assign(Position(x: 3, y: 4), Velocity(a: 5.23), EmptyComponent())

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		nexus.update(membership: family, for: a)
		nexus.update(membership: family, for: b)

		var index: Int = 0

		family.iterate { (e: () -> Entity, p: () -> Position!, v: () -> Velocity!, n: () -> Name?) in

			let pos: Position = p()
			pos.x = 10

			print(e(), pos, n())
			if index == 0 {
				print(v())
			}
			// bla
			index += 1
		}

		family.iterate(components: Position.self, Velocity.self, Name.self) { (_, pos, vel, nm) in
			let position: Position = pos()!
			let velocity: Velocity = vel()!
			let name: Name? = nm()

			_ = position
			_ = velocity
			_ = name
		}

		family.iterate { (e: () -> Entity, p: () -> Position!, v: () -> Velocity!, n: () -> Name?) in

			print(e(), p().x, n())
			if index == 0 {
				print(v())
			}
			// bla
			index += 1
		}

	}

	func testMeasureFamilyIteration() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1+i, y: 2+i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		nexus.entities.forEach { nexus.update(membership: family, for: $0) }

		XCTAssert(family.members.count == number)
		XCTAssert(family.memberIds.count == number)
		XCTAssert(nexus.entities.count == number)

		measure {
			family.iterate(components: Position.self, Velocity.self, Name.self) { (_, pos, vel, nm) in
				let position: Position = pos()!
				let velocity: Velocity = vel()!
				let name: Name? = nm()

				_ = position
				_ = velocity
				_ = name
			}
		}

	}

	func testMeasureFamilyIteration2() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1+i, y: 2+i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		nexus.entities.forEach { nexus.update(membership: family, for: $0) }

		XCTAssert(family.members.count == number)
		XCTAssert(family.memberIds.count == number)
		XCTAssert(nexus.entities.count == number)

		measure {
			family.iterate { (_: () -> Entity, pos: () -> Position!, vel: () -> Velocity!, nm: () -> Name?) in
				let name: Name? = nm()
				let velocity: Velocity = vel()!
				let position: Position = pos()!

				_ = position
				_ = velocity
				_ = name
			}
		}

	}

	func testMeasureEntityIteration() {
		let nexus = Nexus()
		let number: Int = 10_000

		for i in 0..<number {
			nexus.create(entity: "\(i)").assign(Position(x: 1+i, y: 2+i), Name(name: "myName\(i)"), Velocity(a: 3.14), EmptyComponent())
		}

		let family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [Party.self], needsAtLeastOne: [Name.self, EmptyComponent.self])

		nexus.entities.forEach { nexus.update(membership: family, for: $0) }

		measure {
			family.memberIds.forEach { (e) in
				_ = e
			}
		}
	}

}
