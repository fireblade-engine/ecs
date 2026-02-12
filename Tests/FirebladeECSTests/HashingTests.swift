//
//  HashingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 16.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct HashingTests {
    private func makeComponent() -> Int {
        let upperBound: Int = 44
        let range = UInt32.min...UInt32.max
        let high = UInt(UInt32.random(in: range)) << UInt(upperBound)
        let low = UInt(UInt32.random(in: range))
        #expect(high.leadingZeroBitCount < 64 - upperBound)
        #expect(high.trailingZeroBitCount >= upperBound)
        #expect(low.leadingZeroBitCount >= 32)
        #expect(low.trailingZeroBitCount <= 32)
        let rand: UInt = high | low
        let cH = Int(bitPattern: rand)
        return cH
    }

    @Test func collisionsInCritialRange() {
        var hashSet = Set<Int>()

        var range: [UInt32] = Array(0..<1_000_000)

        let maxComponents: Int = 1000
        let components: [Int] = (0..<maxComponents).map { _ in makeComponent() }

        var index: Int = 0
        while let idx = range.popLast() {
            let eId = EntityIdentifier(idx)

            let entityId: EntityIdentifier = eId
            let c = (index % maxComponents)
            index += 1

            let cH: ComponentTypeHash = components[c]

            let h: Int = EntityComponentHash.compose(entityId: entityId, componentTypeHash: cH)

            let (collisionFree, _) = hashSet.insert(h)
            #expect(collisionFree)

            #expect(EntityComponentHash.decompose(h, with: cH) == entityId)
            #expect(EntityComponentHash.decompose(h, with: entityId) == cH)
        }
    }

    @Test func stringHashes() throws {
        let string = "EiMersaufEn1"

        #expect(StringHashing.bernstein_djb2(string) == 13_447_802_024_599_246_090)
        #expect(StringHashing.singer_djb2(string) == 5_428_736_256_651_916_664)
        #expect(StringHashing.sdbm(string) == 15_559_770_072_020_577_201)

        #expect(StringHashing.bernstein_djb2("gamedev") == 229_466_792_000_542)
        #expect(StringHashing.singer_djb2("gamedev") == 2_867_840_411_746_895_486)
        #expect(StringHashing.sdbm("gamedev") == 2_761_443_862_055_442_870)
    }
}
