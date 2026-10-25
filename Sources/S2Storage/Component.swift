//
//  Component.swift
//  S2Storage
//

/// A value-type component (D1) that can be moved across threads (D2).
///
/// Components need no `BitwiseCopyable` conformance: storages handle non-trivial stored properties
/// (`String`, `Array`, class references) by initializing, moving and deinitializing them correctly.
public protocol Component: Sendable {
    /// The dense, process-wide index of this component type, in `0 ..< ComponentMask.capacity`.
    ///
    /// Storages index their per-type state and the per-entity membership bitset by this value, so no
    /// dictionary lookup happens on the hot path. Assignment of the index (macro, registry or by hand) is
    /// outside the storage layer; two types must never share an index.
    static var componentIndex: Int { get }
}

/// Identifies an entity.
///
/// D5 turns this into index plus generation in one `UInt64` (PR 4). Until then only the `index` exists,
/// and indices of destroyed entities are reused without a generation check.
public struct EntityID: Hashable, Sendable {
    /// The slot of the entity; also the key of every sparse index.
    public var index: UInt32

    @inlinable
    public init(index: UInt32) {
        self.index = index
    }
}

/// A fixed-capacity bitset over dense component indices: the component set of one entity, and the
/// signature of one archetype.
public struct ComponentMask: Hashable, Sendable {
    /// The number of distinct component types a mask can describe.
    public static let capacity = 256

    @usableFromInline var bits = SIMD4<UInt64>()

    @inlinable
    public init() {}

    /// A mask holding the given component types.
    @inlinable
    public init<each C: Component>(_ types: repeat (each C).Type) {
        repeat insert((each C).componentIndex)
    }

    @inlinable
    public var isEmpty: Bool {
        bits == SIMD4<UInt64>()
    }

    @inlinable
    public func contains(_ index: Int) -> Bool {
        bits[index >> 6] & (1 << UInt64(truncatingIfNeeded: index & 63)) != 0
    }

    @inlinable
    public mutating func insert(_ index: Int) {
        precondition(index >= 0 && index < Self.capacity, "component index \(index) is out of range")
        bits[index >> 6] |= 1 << UInt64(truncatingIfNeeded: index & 63)
    }

    @inlinable
    public mutating func remove(_ index: Int) {
        bits[index >> 6] &= ~(1 << UInt64(truncatingIfNeeded: index & 63))
    }

    /// Whether every bit of `other` is set in this mask.
    @inlinable
    public func isSuperset(of other: ComponentMask) -> Bool {
        (bits & other.bits) == other.bits
    }

    /// Whether this mask and `other` share no bit.
    @inlinable
    public func isDisjoint(with other: ComponentMask) -> Bool {
        (bits & other.bits) == SIMD4<UInt64>()
    }

    /// Calls `body` with the index of every set bit, ascending.
    @inlinable
    public func forEachIndex(_ body: (Int) -> Void) {
        for word in 0 ..< 4 {
            var remaining = bits[word]
            while remaining != 0 {
                body(word << 6 + remaining.trailingZeroBitCount)
                remaining &= remaining - 1
            }
        }
    }
}

/// The membership predicate of a family: an entity is a member when it has every `requires` component and
/// no `excludes` component.
///
/// The component types an iteration reads or writes are required implicitly; the filter only adds
/// further required components (tags the body does not read) and the excluded ones.
public struct FamilyFilter: Hashable, Sendable {
    /// No additional constraint.
    public static let none = FamilyFilter()

    public var requires: ComponentMask
    public var excludes: ComponentMask

    @inlinable
    public init(requires: ComponentMask = ComponentMask(), excludes: ComponentMask = ComponentMask()) {
        self.requires = requires
        self.excludes = excludes
    }

    @inlinable
    public var isEmpty: Bool {
        requires.isEmpty && excludes.isEmpty
    }

    /// Whether an entity with the component set `mask` is a member (`canBecomeMember` is this test).
    @inlinable
    public func accepts(_ mask: ComponentMask) -> Bool {
        mask.isSuperset(of: requires) && mask.isDisjoint(with: excludes)
    }
}
