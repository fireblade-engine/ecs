//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityIdentifier {
    public static let invalid = EntityIdentifier(.max)

    public typealias Idx = Int

    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    @usableFromInline let id: Idx

    @inlinable
    public init(_ uint32: UInt32) {
        self.id = Idx(uint32)
    }
}

extension EntityIdentifier: Equatable { }
extension EntityIdentifier: Hashable { }
