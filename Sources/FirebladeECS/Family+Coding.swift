//
//  Family+Coding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

#if canImport(Darwin) || swift(>=6.2)
public typealias UserInfoValue = any Sendable
#else
public typealias UserInfoValue = Any
#endif

/// A container for family members (components) used for encoding and decoding.
public struct FamilyMemberContainer<each C: Component> {
    /// The components of the family members.
    public let components: (repeat each C)

    /// Creates a new family member container.
    /// - Parameter components: The components to contain.
    public init(components: (repeat each C)) {
        self.components = components
    }
}

extension CodingUserInfoKey {
    /// A user info key for accessing the nexus coding strategy during encoding and decoding.
    ///
    /// This key is used to pass the `CodingStrategy` from the `Nexus` to the `FamilyMemberContainer`
    /// so that it knows how to encode or decode component types.
    static let nexusCodingStrategy = CodingUserInfoKey(rawValue: "nexusCodingStrategy").unsafelyUnwrapped
}

// MARK: - encoding

extension FamilyMemberContainer: Encodable where repeat each C: Encodable {
    /// Encodes the family members into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        // FIXME: what is with the returning type?
        _ = (repeat try container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

/// A type that can encode values into a native format.
public protocol TopLevelEncoder {
    /// The type this encoder produces.
    associatedtype Output

    /// Encodes an instance of the indicated type.
    ///
    /// - Parameter value: The instance to encode.
    /// - Returns: The encoded data.
    /// - Throws: An error if encoding fails.
    func encode<T: Encodable>(_ value: T) throws -> Self.Output

    /// Contextual user-provided information for use during decoding.
    var userInfo: [CodingUserInfoKey: UserInfoValue] { get set }
}

extension Family where repeat each C: Encodable {
    /// Encode family members (entities) to data using a given encoder.
    ///
    /// The encoded members will *NOT* be removed from the nexus and will also stay present in this family.
    /// - Parameter encoder: The data encoder. Data encoder respects the coding strategy set at `nexus.codingStrategy`.
    /// - Returns: The encoded data.
    /// - Complexity: O(N) where N is the number of family members.
    public func encodeMembers<Encoder: TopLevelEncoder>(using encoder: inout Encoder) throws -> Encoder.Output {
        encoder.userInfo[.nexusCodingStrategy] = nexus.codingStrategy
        let components = [R.Components](self)
        let container = FamilyMemberContainer<R>(components: components)
        return try encoder.encode(container)
    }

    /// Encodes components into a keyed container using a strategy.
    public static func encode(
        components: (repeat each C),
        into container: inout KeyedEncodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws {
        _ = (repeat try container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

// MARK: - decoding

extension FamilyMemberContainer: Decodable where repeat each C: Decodable {
    /// Decodes the family members from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    /// - Complexity: O(N) where N is the number of components in the container.
    public init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.components = (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}

/// A type that can decode values from a native format.
public protocol TopLevelDecoder {
    /// The type this decoder accepts.
    associatedtype Input

    /// Decodes an instance of the indicated type.
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - from: The data to decode from.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    func decode<T: Decodable>(_ type: T.Type, from: Self.Input) throws -> T

    /// Contextual user-provided information for use during decoding.
    var userInfo: [CodingUserInfoKey: UserInfoValue] { get set }
}

extension Family where repeat each C: Decodable {
     /// Decode family members (entities) from given data using a decoder.
    ///
    /// The decoded members will be added to the nexus and will be present in this family.
    /// - Parameters:
    ///   - data: The data decoded by decoder. An unkeyed container of family members (keyed component containers) is expected.
    ///   - decoder: The decoder to use for decoding family member data. Decoder respects the coding strategy set at `nexus.codingStrategy`.
    /// - Returns: returns the newly added entities.
    /// - Complexity: O(N) where N is the number of family members in the data.
    @discardableResult
    public func decodeMembers<Decoder: TopLevelDecoder>(from data: Decoder.Input, using decoder: inout Decoder) throws -> [Entity] {
        decoder.userInfo[.nexusCodingStrategy] = nexus.codingStrategy
        let familyMembers = try decoder.decode(FamilyMemberContainer<R>.self, from: data)
        return familyMembers.components
            .map { createMember(with: $0) }
    }
    
    /// Decodes components from a keyed container using a strategy.
    public static func decode(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws -> (repeat each C) {
        return (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}
