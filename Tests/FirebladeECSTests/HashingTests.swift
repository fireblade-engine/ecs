//
//  HashingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 16.10.17.
//

#if DEBUG
@testable import FirebladeECS
import XCTest

class HashingTests: XCTestCase {
    func makeComponent() -> Int {
        let upperBound: Int = 44
        let range = UInt32.min...UInt32.max
        let high = UInt(UInt32.random(in: range)) << UInt(upperBound)
        let low = UInt(UInt32.random(in: range))
        XCTAssertTrue(high.leadingZeroBitCount < 64 - upperBound)
        XCTAssertTrue(high.trailingZeroBitCount >= upperBound)
        XCTAssertTrue(low.leadingZeroBitCount >= 32)
        XCTAssertTrue(low.trailingZeroBitCount <= 32)
        let rand: UInt = high | low
        let cH = Int(bitPattern: rand)
        return cH
    }

    func testCollisionsInCritialRange() {
        var hashSet: Set<Int> = Set<Int>()

        var range: CountableRange<UInt32> = 0 ..< 1_000_000

        let maxComponents: Int = 1000
        let components: [Int] = (0..<maxComponents).map { _ in makeComponent() }

        var index: Int = 0
        while let idx: UInt32 = range.popLast() {
            let eId = EntityIdentifier(idx)

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
#endif
