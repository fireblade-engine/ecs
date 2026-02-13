//
//  Family+Coding+Foundation.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.26.
//

#if canImport(Foundation)
import Foundation

extension Family where repeat each C: Encodable {
    /// Encode family members (entities) to data using a given encoder.
    ///
    /// The encoded members will *NOT* be removed from the nexus and will also stay present in this family.
    /// - Parameter encoder: The data encoder. Data encoder respects the coding strategy set at `nexus.codingStrategy`.
    /// - Returns: The encoded data.
    /// - Complexity: O(N) where N is the number of family members.
    public func encodeMembers(using encoder: inout JSONEncoder) throws -> Data {
        encoder.userInfo[CodingUserInfoKey.nexusCodingStrategy] = nexus.codingStrategy
        let container = FamilyMemberContainer<repeat each C>(components: makeIterator())
        return try encoder.encode(container)
    }
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
    public func decodeMembers(from data: Data, using decoder: inout JSONDecoder) throws -> [Entity] {
        decoder.userInfo[CodingUserInfoKey.nexusCodingStrategy] = nexus.codingStrategy
        let familyMembers = try decoder.decode(FamilyMemberContainer<repeat each C>.self, from: data)
        return familyMembers.components
            .map { (memberComponents: (repeat each C)) in
                createMember(with: repeat each memberComponents)
            }
    }
}

#endif
