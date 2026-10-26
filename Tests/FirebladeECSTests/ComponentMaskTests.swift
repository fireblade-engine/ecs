//
//  ComponentMaskTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

import Testing
@testable import FirebladeECS

@Suite struct ComponentMaskTests {
    typealias Mask = Nexus.ComponentMask

    private func mask(_ indices: Int...) -> Mask {
        var mask = Mask()
        for index in indices {
            mask.insert(index)
        }
        return mask
    }

    @Test func insertContainsRemoveAcrossTheInlineBoundary() {
        var mask = Mask()
        #expect(mask.isEmpty)
        for index in [0, 63, 64, 127, 128, 129, 191, 192, 1000] {
            mask.insert(index)
            #expect(mask.contains(index))
        }
        #expect(mask.count == 9)
        #expect(!mask.contains(1))
        #expect(!mask.contains(130))
        mask.remove(64)
        mask.remove(129)
        #expect(!mask.contains(64) && !mask.contains(129))
        #expect(mask.contains(63) && mask.contains(128))
    }

    @Test func outOfRangeIndicesAreAbsent() {
        let mask = mask(3, 300)
        #expect(!mask.contains(-1))
        #expect(!mask.contains(Int.min))
        #expect(!mask.contains(100_000))
        #expect(!mask.contains(Int.max))
    }

    @Test func removingOutOfRangeIndicesChangesNothing() {
        var mask = mask(3, 300)
        let before = mask
        mask.remove(-1)
        mask.remove(100_000)
        #expect(mask == before)
    }

    @Test func overflowIsCanonical() {
        var grown = mask(5, 1000)
        grown.remove(1000)
        #expect(grown == mask(5))
        #expect(grown.hashValue == mask(5).hashValue)
        grown.remove(5)
        #expect(grown.isEmpty)
        #expect(grown == Mask())
    }

    @Test func growsWithoutALimit() {
        var mask = Mask()
        for index in stride(from: 0, to: 5000, by: 7) {
            mask.insert(index)
        }
        #expect(mask.count == (0 ..< 5000).filter { $0 % 7 == 0 }.count)
        var visited: [Int] = []
        mask.forEachIndex { visited.append($0) }
        #expect(visited == (0 ..< 5000).filter { $0 % 7 == 0 })
    }

    @Test func supersetAndDisjointIncludeTheOverflow() {
        let entity = mask(1, 130, 400)
        #expect(entity.isSuperset(of: mask(1, 400)))
        #expect(entity.isSuperset(of: Mask()))
        #expect(!entity.isSuperset(of: mask(1, 401)))
        #expect(!mask(1).isSuperset(of: mask(500)))
        #expect(entity.isDisjoint(with: mask(2, 131, 401)))
        #expect(entity.isDisjoint(with: Mask()))
        #expect(!entity.isDisjoint(with: mask(2, 400)))
        #expect(mask(1).isDisjoint(with: mask(900)))
    }

    @Test func familyFilterAcceptsByRequiredAndExcluded() {
        let filter = Nexus.FamilyFilter(requires: mask(1, 200), excludes: mask(2, 300))
        #expect(filter.accepts(mask(1, 200)))
        #expect(filter.accepts(mask(1, 200, 5)))
        #expect(!filter.accepts(mask(1)))
        #expect(!filter.accepts(mask(1, 200, 2)))
        #expect(!filter.accepts(mask(1, 200, 300)))
    }

    #if os(macOS) || os(Linux) || os(Windows)
        @Test func insertingANegativeIndexTraps() async {
            await #expect(processExitsWith: .failure) {
                var mask = Nexus.ComponentMask()
                mask.insert(-1)
            }
        }
    #endif
}
