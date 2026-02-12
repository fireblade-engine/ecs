//
//  FamilyEncoding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

/// A protocol that defines the requirements for encoding a family of components.
public protocol FamilyEncoding: FamilyRequirementsManaging {
    /// Encodes an array of component collections into an unkeyed container.
    /// - Parameters:
    ///   - componentsArray: The array of component collections to encode.
    ///   - container: The unkeyed encoding container to write to.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Throws: An error if encoding fails.
    static func encode(componentsArray: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws

    /// Encodes a collection of components into a keyed container.
    /// - Parameters:
    ///   - components: The component collection to encode.
    ///   - container: The keyed encoding container to write to.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Throws: An error if encoding fails.
    static func encode(components: Components, into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws
}

extension FamilyEncoding {
    /// Encodes an array of component collections into an unkeyed container.
    ///
    /// This implementation iterates through the array, encoding each element as a nested keyed container.
    ///
    /// - Parameters:
    ///   - componentsArray: The array of component collections to encode.
    ///   - container: The unkeyed encoding container to write to.
    ///   - strategy: The coding strategy to use for determining coding keys.
    /// - Throws: An error if encoding fails.
    public static func encode(componentsArray: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws {
        for comps in componentsArray {
            var container = container.nestedContainer(keyedBy: DynamicCodingKey.self)
            try Self.encode(components: comps, into: &container, using: strategy)
        }
    }
}
