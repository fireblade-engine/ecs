//
//  EntityIdentifier+Codable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension EntityIdentifier: Codable {
    /// Encodes the slot index into a single value container.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    /// - Complexity: O(1)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(index)
    }

    /// Decodes an entity identifier of generation 1 from a single slot index.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    /// - Complexity: O(1)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(index: container.decode(Index.self), generation: 1)
    }
}
