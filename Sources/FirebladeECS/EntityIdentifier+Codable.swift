//
//  EntityIdentifier+Codable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension EntityIdentifier: Codable {
    /// Encodes the raw identifier value into a single value container.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    /// - Complexity: O(1)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Decodes an entity identifier from a single raw identifier value.
    ///
    /// While a snapshot of format version 1 or 2 is decoded, the value is a 32 bit slot index
    /// and decodes to an identifier of generation 0.
    /// Index 0 is reserved: while a snapshot is decoded, it decodes to the identifier of the entity
    /// that replaced the entity with index 0 in the snapshot (see ``NexusSnapshot``).
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    /// - Complexity: O(1)
    public init(from decoder: Decoder) throws {
        let source = try Self.decodeSource(from: decoder)
        let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver
        let isLegacyReserved = source == .invalid && resolver?.decodesLegacyIdentifiers == true
        self = (isLegacyReserved ? resolver?.mapping[source] : nil) ?? source
    }

    /// Decodes an entity identifier as it is encoded, without replacing the reserved index 0 of legacy snapshots.
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The encoded (source) identifier.
    /// - Throws: An error if decoding fails.
    static func decodeSource(from decoder: Decoder) throws -> EntityIdentifier {
        let container = try decoder.singleValueContainer()
        let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver
        if resolver?.decodesLegacyIdentifiers == true {
            return try EntityIdentifier(index: container.decode(Index.self), generation: 0)
        }
        return try EntityIdentifier(rawValue: container.decode(UInt64.self))
    }
}

extension EntityIdentifier {
    /// An encoded entity identifier that is decoded as it is, see ``EntityIdentifier/decodeSource(from:)``.
    struct Source: Decodable {
        let value: EntityIdentifier

        init(from decoder: Decoder) throws {
            value = try EntityIdentifier.decodeSource(from: decoder)
        }
    }
}
