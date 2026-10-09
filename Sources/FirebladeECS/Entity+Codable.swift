//
//  Entity+Codable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Entity: Codable {
    /// Encodes the entity as its identifier.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    /// - Complexity: O(1)
    public func encode(to encoder: Encoder) throws {
        try identifier.encode(to: encoder)
    }

    /// Decodes an entity reference using the ``EntityReferenceResolver`` provided
    /// via `decoder.userInfo[.nexusEntityResolver]`.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: ``EntityReferenceError`` if no resolver is provided or the identifier is not mapped.
    /// - Complexity: O(1)
    public init(from decoder: Decoder) throws {
        guard let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver else {
            throw EntityReferenceError.missingResolver
        }
        self = try resolver.resolve(EntityIdentifier(from: decoder))
    }
}
