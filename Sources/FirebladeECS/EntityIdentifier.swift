//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **EntityIdentifier**
///
/// An entity identifier represents the unique identity of an entity.
public struct EntityIdentifier {
    /// Entity identifier type.
    ///
    /// Provides 4294967295 unique identifiers.
    public typealias Identifier = UInt32

    /// The entity identifier.
    public let id: Identifier

    @inlinable
    public init(_ id: Identifier) {
        self.init(rawValue: id)
    }
}

extension EntityIdentifier: Equatable { }
extension EntityIdentifier: Hashable { }

extension EntityIdentifier: RawRepresentable {
    /// The entity identifier represented as a raw value.
    @inline(__always)
    public var rawValue: Identifier { id }

    @inlinable
    public init(rawValue: Identifier) {
        self.id = rawValue
    }
}

extension EntityIdentifier: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Identifier) {
        self.init(value)
    }
}

extension EntityIdentifier {
    /// Invalid entity identifier
    ///
    /// Used to represent an invalid entity identifier.
    public static let invalid = EntityIdentifier(.max)
}

extension EntityIdentifier {
    /// Provides the entity identifier as an index
    ///
    /// This is a convenience property for collection indexing and does not represent the raw identifier.
    ///
    /// Use `id` or `rawValue` instead.
    @inline(__always)
    public var index: Int { Int(id) }
}
