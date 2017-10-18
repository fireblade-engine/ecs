//
//  HashingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 16.10.17.
//

import Darwin
import XCTest
@testable import FirebladeECS

class HashingTests: XCTestCase {

	func testCollisionsInCritialRange() {

		var hashSet: Set<Int> = Set<Int>()

		var range: CountableRange<EntityIdentifier> = 0 ..< 1_000_000

		let maxComponents: Int = 1000
		let components: [Int] = (0..<maxComponents).map { _ in makeComponent() }

		var index: Int = 0
		while let eId: EntityIdentifier = range.popLast() {

			let entityId: EntityIdentifier = eId
			let c = (index % maxComponents)
			index += 1

			let cH: ComponentTypeHash = components[c]

			let h: Int = EntityComponentHash.compose(entityId: entityId, componentTypeHash: cH)

			let (collisionFree, _) = hashSet.insert(h)
			XCTAssert(collisionFree)

			XCTAssert(EntityComponentHash.decompose(h, with: cH) == entityId)
			XCTAssert(EntityComponentHash.decompose(h, with: entityId) == cH)
		}
	}
}

// MARK: - helper
extension HashingTests {

	func makeComponent() -> Int {
		let upperBound: Int = 44
		let high = UInt(arc4random()) << UInt(upperBound)
		let low = UInt(arc4random())
		assert(high.leadingZeroBitCount < 64-upperBound)
		assert(high.trailingZeroBitCount >= upperBound)
		assert(low.leadingZeroBitCount >= 32)
		assert(low.trailingZeroBitCount <= 32)
		let rand: UInt = high | low
		let cH = Int(bitPattern: rand)
		return cH
	}
}
