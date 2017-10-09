//
//  PerformanceTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import XCTest
@testable import FirebladeECS

class PerformanceTests: XCTestCase {

	var eventHub: DefaultEventHub = DefaultEventHub()

	var entityArray: [Entity] = [Entity]()
	var entityContArray: ContiguousArray<Entity> = ContiguousArray<Entity>()

	var entitySet: Set<Entity> = Set<Entity>()
	var entityMap: [UEI: Entity] = [UEI: Entity]()

	static let maxNum: Int = 65536

	override func setUp() {
		super.setUp()
		entitySet.removeAll()
		entitySet.reserveCapacity(0)

		entityMap.removeAll()
		entityMap.reserveCapacity(0)

		entityArray.removeAll()
		entityArray.reserveCapacity(0)

		entityContArray.removeAll()
		entityContArray.reserveCapacity(0)

	}

	func testEntitySetLinearInsert() {
		measure {
			for i in 0..<65536 {
				let newEntity = Entity(uei: UEI(i), dispatcher: eventHub)
				entitySet.insert(newEntity)

			}
		}
	}

	func testEntityMapLinearInsert() {
		entityMap.removeAll()
		entityMap.reserveCapacity(0)
		measure {
			for i in 0..<65536 {
				let newEntity = Entity(uei: UEI(i), dispatcher: eventHub)
				entityMap[newEntity.uei] = newEntity

			}
		}
	}

	func testEntityMapUpdateLinarInsert() {
		entityMap.removeAll()
		entityMap.reserveCapacity(0)

		measure {
			for i in 0..<65536 {
				let newEntity = Entity(uei: UEI(i), dispatcher: eventHub)
				entityMap.updateValue(newEntity, forKey: newEntity.uei)

			}
		}
	}

	func testEntityContArrayLinearInsert() {
		measure {
			for i in 0..<65536 {
				let newEntity = Entity(uei: UEI(i), dispatcher: eventHub)
				entityContArray.append(newEntity)
			}
		}
	}

	func testEntityContArrayFixPosInsert() {

		let count: Int = Int(65536)
		var entityContArray2 = ContiguousArray<Entity!>(repeating: nil, count: count)
		entityContArray2.reserveCapacity(count)
		measure {
			for i: Int in 0..<count-1 {
				let uei = UEI(i)
				let newEntity = Entity(uei: uei, dispatcher: eventHub)

				entityContArray2[i] = newEntity
			}
		}
	}

	func testEntityArrayLinearInsert() {
		measure {
			for i in 0..<65536 {
				let newEntity = Entity(uei: UEI(i), dispatcher: eventHub)
				entityArray.append(newEntity)
			}
		}
	}

}
