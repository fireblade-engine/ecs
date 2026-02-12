//
//  Family+Coding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

/// A container for family members (components) used for encoding and decoding.
public struct FamilyMemberContainer<R: FamilyRequirementsManaging> {
    /// The components of the family members.
    public let components: [R.Components]

    /// Creates a new family member container.
    /// - Parameter components: The components to contain.
    public init(components: [R.Components]) {
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

extension FamilyMemberContainer: Encodable where R: FamilyEncoding {
    /// Encodes the family members into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var familyContainer = encoder.unkeyedContainer()
        try R.encode(componentsArray: components, into: &familyContainer, using: strategy)
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
    var userInfo: [CodingUserInfoKey: any Sendable] { get set }
}

extension Family where R: FamilyEncoding {
    /// Encode family members (entities) to data using a given encoder.
    ///
    /// The encoded members will *NOT* be removed from the nexus and will also stay present in this family.
    /// - Parameter encoder: The data encoder. Data encoder respects the coding strategy set at `nexus.codingStrategy`.
    /// - Returns: The encoded data.
    public func encodeMembers<Encoder: TopLevelEncoder>(using encoder: inout Encoder) throws -> Encoder.Output {
        encoder.userInfo[.nexusCodingStrategy] = nexus.codingStrategy
        let components = [R.Components](self)
        let container = FamilyMemberContainer<R>(components: components)
        return try encoder.encode(container)
    }
}

// MARK: - decoding

extension FamilyMemberContainer: Decodable where R: FamilyDecoding {
    /// Creates a new family member container by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        var familyContainer = try decoder.unkeyedContainer()
        let strategy = decoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        components = try R.decode(componentsIn: &familyContainer, using: strategy)
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
    var userInfo: [CodingUserInfoKey: any Sendable] { get set }
}

extension Family where R: FamilyDecoding {
    /// Decode family members (entities) from given data using a decoder.
    ///
    /// The decoded members will be added to the nexus and will be present in this family.
    /// - Parameters:
    ///   - data: The data decoded by decoder. An unkeyed container of family members (keyed component containers) is expected.
    ///   - decoder: The decoder to use for decoding family member data. Decoder respects the coding strategy set at `nexus.codingStrategy`.
    /// - Returns: returns the newly added entities.
    @discardableResult
    public func decodeMembers<Decoder: TopLevelDecoder>(from data: Decoder.Input, using decoder: inout Decoder) throws -> [Entity] {
        decoder.userInfo[.nexusCodingStrategy] = nexus.codingStrategy
        let familyMembers = try decoder.decode(FamilyMemberContainer<R>.self, from: data)
        return familyMembers.components
            .map { createMember(with: $0) }
    }
}
