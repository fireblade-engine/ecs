//
//  ComponentMask.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// A growable bitset over dense component indices: the component set of one entity, and the signature of a family.
    ///
    /// The first 128 indices live inline, so typical masks cost no allocation and no indirection.
    /// Further words are allocated when an index above 127 is inserted, so there is no limit on the number of component types.
    /// The overflow is canonical (`nil` or ending in a non-zero word), which makes equality and hashing structural.
    @usableFromInline
    struct ComponentMask: Hashable, Sendable {
        /// The number of indices that are stored inline.
        @usableFromInline static let inlineCapacity = 128

        @usableFromInline var low = SIMD2<UInt64>()
        /// Words for the indices from `inlineCapacity` on.
        @usableFromInline var high: ContiguousArray<UInt64>?

        @inlinable
        init() {}

        /// A mask holding the given component types.
        @inlinable
        init<each C: Component>(_ types: repeat (each C).Type) {
            repeat insert((each C).componentIndex)
        }

        @inlinable var isEmpty: Bool {
            low == SIMD2<UInt64>() && high == nil
        }

        /// The number of indices in the mask.
        @usableFromInline var count: Int {
            var result = low[0].nonzeroBitCount + low[1].nonzeroBitCount
            for word in high ?? [] {
                result += word.nonzeroBitCount
            }
            return result
        }

        @inlinable
        func contains(_ index: Int) -> Bool {
            guard index >= 0 else {
                return false
            }
            let bit: UInt64 = 1 << UInt64(truncatingIfNeeded: index & 63)
            if index < Self.inlineCapacity {
                return low[index >> 6] & bit != 0
            }
            let word = (index >> 6) - 2
            guard let high, word < high.count else {
                return false
            }
            return high[word] & bit != 0
        }

        /// Inserts a component index.
        /// - Precondition: `index` is not negative.
        @inlinable
        mutating func insert(_ index: Int) {
            precondition(index >= 0, "component index \(index) is out of range")
            let bit: UInt64 = 1 << UInt64(truncatingIfNeeded: index & 63)
            if index < Self.inlineCapacity {
                low[index >> 6] |= bit
                return
            }
            insertHigh(index >> 6 - 2, bit)
        }

        @usableFromInline
        mutating func insertHigh(_ word: Int, _ bit: UInt64) {
            if high == nil {
                high = []
            }
            let missing = word + 1 - high.unsafelyUnwrapped.count
            if missing > 0 {
                high?.append(contentsOf: repeatElement(0, count: missing))
            }
            high?[word] |= bit
        }

        @inlinable
        mutating func remove(_ index: Int) {
            guard index >= 0 else {
                return
            }
            let bit: UInt64 = 1 << UInt64(truncatingIfNeeded: index & 63)
            if index < Self.inlineCapacity {
                low[index >> 6] &= ~bit
                return
            }
            removeHigh(index >> 6 - 2, bit)
        }

        @usableFromInline
        mutating func removeHigh(_ word: Int, _ bit: UInt64) {
            guard let count = high?.count, word < count else {
                return
            }
            high?[word] &= ~bit
            while high?.last == 0 {
                high?.removeLast()
            }
            if high?.isEmpty == true {
                high = nil
            }
        }

        /// Whether every index of `other` is in this mask.
        @inlinable
        func isSuperset(of other: ComponentMask) -> Bool {
            guard (low & other.low) == other.low else {
                return false
            }
            guard let otherHigh = other.high else {
                return true
            }
            guard let high, high.count >= otherHigh.count else {
                return false
            }
            for word in otherHigh.indices where high[word] & otherHigh[word] != otherHigh[word] {
                return false
            }
            return true
        }

        /// Whether this mask and `other` share no index.
        @inlinable
        func isDisjoint(with other: ComponentMask) -> Bool {
            guard (low & other.low) == SIMD2<UInt64>() else {
                return false
            }
            guard let high, let otherHigh = other.high else {
                return true
            }
            for word in 0 ..< min(high.count, otherHigh.count) where high[word] & otherHigh[word] != 0 {
                return false
            }
            return true
        }

        /// Calls `body` with every index in the mask, ascending.
        @inlinable
        func forEachIndex(_ body: (Int) -> Void) {
            for word in 0 ..< 2 {
                var remaining = low[word]
                while remaining != 0 {
                    body(word << 6 + remaining.trailingZeroBitCount)
                    remaining &= remaining - 1
                }
            }
            for (offset, word) in (high ?? []).enumerated() {
                var remaining = word
                while remaining != 0 {
                    body((offset + 2) << 6 + remaining.trailingZeroBitCount)
                    remaining &= remaining - 1
                }
            }
        }
    }

    /// The membership predicate of a family: an entity is a member when it has every `requires` component and no `excludes` component.
    @usableFromInline
    struct FamilyFilter: Hashable, Sendable {
        @usableFromInline var requires: ComponentMask
        @usableFromInline var excludes: ComponentMask

        @inlinable
        init(requires: ComponentMask = ComponentMask(), excludes: ComponentMask = ComponentMask()) {
            self.requires = requires
            self.excludes = excludes
        }

        /// Whether an entity with the component set `mask` is a member.
        @inlinable
        func accepts(_ mask: ComponentMask) -> Bool {
            mask.isSuperset(of: requires) && mask.isDisjoint(with: excludes)
        }
    }
}
