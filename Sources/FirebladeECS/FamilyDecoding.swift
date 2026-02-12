//
//  FamilyDecoding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

/// A protocol that defines the requirements for decoding a family of components.
public protocol FamilyDecoding: FamilyRequirementsManaging {
    /// Decodes an array of component collections from an unkeyed container.
    /// - Parameters:
    ///   - unkeyedContainer: The unkeyed decoding container to read from.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Returns: An array of decoded component collections.
    /// - Throws: An error if decoding fails.
    static func decode(componentsIn unkeyedContainer: inout UnkeyedDecodingContainer, using strategy: CodingStrategy) throws -> [Components]

    /// Decodes a collection of components from a keyed container.
    /// - Parameters:
    ///   - container: The keyed decoding container to read from.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Returns: A decoded component collection.
    /// - Throws: An error if decoding fails.
    static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> Components
}

extension FamilyDecoding {
    /// Decodes an array of component collections from an unkeyed container.
    ///
    /// This implementation iterates through the unkeyed container, decoding each element as a nested keyed container.
    ///
    /// - Parameters:
    ///   - unkeyedContainer: The unkeyed decoding container to read from.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Returns: An array of decoded component collections.
    /// - Throws: An error if decoding fails.
    /// - Complexity: O(N) where N is the number of elements in the container.
    public static func decode(componentsIn unkeyedContainer: inout UnkeyedDecodingContainer, using strategy: CodingStrategy) throws -> [Components] {
        var components = [Components]()
        if let count = unkeyedContainer.count {
            components.reserveCapacity(count)
        }
        while !unkeyedContainer.isAtEnd {
            let container = try unkeyedContainer.nestedContainer(keyedBy: DynamicCodingKey.self)
            let comps = try Self.decode(componentsIn: container, using: strategy)
            components.append(comps)
        }
        return components
    }
}
