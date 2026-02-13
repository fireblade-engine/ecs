//
//  Family+Coding.swift
//  FirebladeECS
//
//  Created by Conductor on 2026-02-13.
//

#if canImport(Foundation)
import Foundation

extension Family where repeat each C: Encodable {
    /// Encodes the components of a single entity into a keyed container.
    /// - Parameters:
    ///   - components: The components to encode.
    ///   - container: The encoding container to write to.
    ///   - strategy: The coding strategy to determine keys.
    /// - Throws: An error if encoding fails.
    public static func encode(
        components: (repeat each C),
        into container: inout KeyedEncodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws {
        // Encode each component using the strategy for keys
        _ = (repeat try container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

extension Family where repeat each C: Decodable {
    /// Decodes components for a family member from a keyed container.
    /// - Parameters:
    ///   - container: The decoding container to read from.
    ///   - strategy: The coding strategy to determine keys.
    /// - Returns: A tuple of decoded components.
    /// - Throws: An error if decoding fails.
    public static func decode(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws -> (repeat each C) {
        return (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}
#endif
