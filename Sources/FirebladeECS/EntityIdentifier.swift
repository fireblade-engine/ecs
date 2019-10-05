//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityIdentifier: Identifiable {
    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    public let id: Int

    public init(_ uint32: UInt32) {
        self.id = Int(uint32)
    }
}
extension EntityIdentifier {
    public static let invalid = EntityIdentifier(.max)
}

extension EntityIdentifier: Equatable { }
extension EntityIdentifier: Hashable { }
extension EntityIdentifier: Codable { }
extension EntityIdentifier: Comparable {
    @inlinable
    public static func < (lhs: EntityIdentifier, rhs: EntityIdentifier) -> Bool {
        return lhs.id < rhs.id
    }
}
