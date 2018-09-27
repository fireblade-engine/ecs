//
//  HashingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 16.10.17.
//

@testable import FirebladeECS
import XCTest

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

	func testMeasureCombineHash() {
		let a: Set<Int> = Set<Int>([14_561_291, 26_451_562, 34_562_182, 488_972_556, 5_128_426_962, 68_211_812])
		let b: Set<Int> = Set<Int>([1_083_838, 912_312, 83_333, 71_234_555, 4_343_234])
		let c: Set<Int> = Set<Int>([3_410_346_899_765, 90_000_002, 12_212_321, 71, 6_123_345_676_543])

		let input: ContiguousArray<Int> = ContiguousArray<Int>(arrayLiteral: a.hashValue, b.hashValue, c.hashValue)
		measure {
			for _ in 0..<1_000_000 {
				let hashRes: Int = FirebladeECS.hash(combine: input)
				_ = hashRes
			}
		}
	}

	func testMeasureSetOfSetHash() {
		let a: Set<Int> = Set<Int>([14_561_291, 26_451_562, 34_562_182, 488_972_556, 5_128_426_962, 68_211_812])
		let b: Set<Int> = Set<Int>([1_083_838, 912_312, 83_333, 71_234_555, 4_343_234])
		let c: Set<Int> = Set<Int>([3_410_346_899_765, 90_000_002, 12_212_321, 71, 6_123_345_676_543])

		let input = Set<Set<Int>>(arrayLiteral: a, b, c)
		measure {
			for _ in 0..<1_000_000 {
				let hash: Int = input.hashValue
				_ = hash
			}
		}
	}

}

// MARK: - helper
extension HashingTests {

	func makeComponent() -> Int {
		let upperBound: Int = 44
		let high = UInt(arc4random()) << UInt(upperBound)
		let low = UInt(arc4random())
		assert(high.leadingZeroBitCount < 64 - upperBound)
		assert(high.trailingZeroBitCount >= upperBound)
		assert(low.leadingZeroBitCount >= 32)
		assert(low.trailingZeroBitCount <= 32)
		let rand: UInt = high | low
		let cH = Int(bitPattern: rand)
		return cH
	}
}
