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
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    /// - Complexity: O(1)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(Identifier.self))
    }
}
