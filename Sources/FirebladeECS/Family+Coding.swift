//
//  Family+Coding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

/// A container for family members (components) used for encoding and decoding.
public struct FamilyMemberContainer<each C: Component> {
    /// The components of the family members.
    public let components: [(repeat each C)]

    /// Creates a new family member container.
    /// - Parameter components: The components to contain.
    public init(components: (repeat each C)...) {
        self.components = components
    }

    public init<S>(component: S) where S: Sequence, S.Element == (repeat each C) {
        self.components = Array(component)
    }

    public init(components: Family<repeat each C>.ComponentsIterator) {
        self.components = Array(components)
    }
}

extension CodingUserInfoKey {
    /// A user info key for accessing the nexus coding strategy during encoding and decoding.
    ///
    /// This key is used to pass the `CodingStrategy` from the `Nexus` to the `FamilyMemberContainer`
    /// so that it knows how to encode or decode component types.
    public static let nexusCodingStrategy = CodingUserInfoKey(rawValue: "nexusCodingStrategy").unsafelyUnwrapped
}

// MARK: - encoding

extension FamilyMemberContainer: Encodable where repeat each C: Encodable {
    /// Encodes the family members into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[CodingUserInfoKey.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var familyContainer = encoder.unkeyedContainer()
        for memberComponents in components {
            var container = familyContainer.nestedContainer(keyedBy: DynamicCodingKey.self)
            _ = try (repeat container.encode(each memberComponents, forKey: strategy.codingKey(for: (each C).self)))
        }
    }
}

extension Family where repeat each C: Encodable {
    /// Encodes components into a keyed container using a strategy.
    public static func encode(
        components: (repeat each C),
        into container: inout KeyedEncodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws {
        _ = try (repeat container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

// MARK: - decoding

extension FamilyMemberContainer: Decodable where repeat each C: Decodable {
    // Decodes the family members from the given decoder.
    // - Parameter decoder: The decoder to read data from.
    // - Throws: An error if decoding fails.
    // - Complexity: O(N) where N is the number of components in the container.
    public init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[CodingUserInfoKey.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var familyContainer = try decoder.unkeyedContainer()
        var componentsList: [(repeat each C)] = []
        while !familyContainer.isAtEnd {
            let container = try familyContainer.nestedContainer(keyedBy: DynamicCodingKey.self)
            let memberComponents = try (repeat container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
            componentsList.append(memberComponents)
        }
        components = componentsList
    }
}

extension Family where repeat each C: Decodable {
    /// Decodes components from a keyed container using a strategy.
    public static func decode(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws -> (repeat each C) {
        try (repeat container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}
