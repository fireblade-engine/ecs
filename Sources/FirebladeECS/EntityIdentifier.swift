//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **EntityIdentifier**
///
/// An entity identifier represents the unique identity of an entity over the lifetime of a ``Nexus``.
///
/// The 64 bit raw value consists of the `index` of the entity's slot in the low 32 bits and the slot's `generation` in the high 32 bits.
/// A slot is reused after its entity is destroyed, but with an increased generation.
/// An identifier of a destroyed entity (a stale identifier) therefore never matches a later entity in the same slot,
/// see ``Nexus/isAlive(_:)`` and ``Nexus/entity(_:)``.
///
/// The slot index 0 is reserved and never handed out, as in flecs, so that the raw value `0` (index 0, generation 0)
/// is never a live identifier and can serve as ``invalid``. Generations start at 0.
public struct EntityIdentifier: Hashable, Sendable, BitwiseCopyable {
    /// The type of the slot index.
    public typealias Index = UInt32

    /// The type of the slot generation.
    public typealias Generation = UInt32

    /// The raw identifier value: the generation in the high 32 bits, the index in the low 32 bits.
    ///
    /// Use the raw value for snapshots and networking only.
    public let rawValue: UInt64

    /// Initializes an entity identifier from a raw value.
    /// - Parameter rawValue: The raw identifier value, as obtained from ``rawValue``.
    /// - Complexity: O(1)
    @inlinable
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// Initializes an entity identifier from a slot index and generation.
    /// - Parameters:
    ///   - index: The index of the slot.
    ///   - generation: The generation of the slot.
    /// - Complexity: O(1)
    @inlinable
    public init(index: Index, generation: Generation) {
        self.init(rawValue: UInt64(generation) << 32 | UInt64(index))
    }

    /// The index of the slot this identifier refers to.
    /// - Complexity: O(1)
    @inlinable public var index: Index {
        Index(truncatingIfNeeded: rawValue)
    }

    /// The generation of the slot this identifier refers to.
    /// - Complexity: O(1)
    @inlinable public var generation: Generation {
        Generation(truncatingIfNeeded: rawValue >> 32)
    }
}

extension EntityIdentifier {
    /// Invalid entity identifier
    ///
    /// Used to represent the absence of an entity identifier. No entity ever has this identifier.
    /// - Complexity: O(1)
    public static let invalid = EntityIdentifier(rawValue: 0)

    /// A Boolean value that indicates whether this identifier is not ``invalid``.
    ///
    /// A valid identifier can still be stale, see ``Nexus/isAlive(_:)``.
    /// - Complexity: O(1)
    @inlinable public var isValid: Bool {
        self != .invalid
    }
}

extension EntityIdentifier: CustomStringConvertible {
    /// The identifier as `<index>v<generation>`, e.g. `7v3`.
    public var description: String {
        "\(index)v\(generation)"
    }
}

extension EntityIdentifier {
    /// The type of the slot index in entity identifiers of earlier versions.
    @available(*, deprecated, renamed: "Index")
    public typealias Identifier = UInt32

    /// Initializes an entity identifier of generation 0 from a slot index.
    ///
    /// Generation 0 is the first generation of every slot, which is the generation entity identifiers of earlier versions decode with.
    /// - Parameter id: The slot index.
    @available(*, deprecated, message: "Use init(index:generation:). This initializer creates an identifier of generation 0, which is stale once the entity is destroyed.")
    @inlinable
    public init(_ id: Index) {
        self.init(index: id, generation: 0)
    }

    /// The slot index of the identifier.
    @available(*, deprecated, renamed: "index")
    @inlinable public var id: Index {
        index
    }
}
