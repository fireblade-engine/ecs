//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityIdentifier {
    public static let invalid = EntityIdentifier(.max)

    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    public let index: Int

    private init() {
        self = .invalid
    }

    public init(_ uint32: UInt32) {
        self.index = Int(uint32)
    }
}

extension EntityIdentifier: Equatable { }

extension EntityIdentifier: Hashable { }

extension EntityIdentifier: Comparable {
    @inlinable
    public static func < (lhs: EntityIdentifier, rhs: EntityIdentifier) -> Bool {
        return lhs.index < rhs.index
    }
}
