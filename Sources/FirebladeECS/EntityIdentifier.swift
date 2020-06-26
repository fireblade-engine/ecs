//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityIdentifier {
    static let invalid = EntityIdentifier(.max)

    /// provides 4294967295 unique identifiers since it's constrained to UInt32 - invalid.
    @usableFromInline let id: Int

    @usableFromInline
    init(_ uint32: UInt32) {
        self.id = Int(uint32)
    }
}

extension EntityIdentifier: Equatable { }
extension EntityIdentifier: Hashable { }
