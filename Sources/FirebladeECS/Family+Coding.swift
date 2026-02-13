//
//  Family+Coding.swift
//  FirebladeECS
//
//  Created by Conductor on 2026-02-13.
//

#if canImport(Foundation)
import Foundation

#if canImport(Darwin) || swift(>=6.2)
public typealias UserInfoValue = any Sendable
#else
public typealias UserInfoValue = Any
#endif

public extension CodingUserInfoKey {
    /// A user info key for accessing the nexus coding strategy during encoding and decoding.
    static let nexusCodingStrategy = CodingUserInfoKey(rawValue: "nexusCodingStrategy").unsafelyUnwrapped
}

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

extension FamilyMemberContainer: Encodable where repeat each C: Encodable {
    public func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        _ = (repeat try container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

extension FamilyMemberContainer: Decodable where repeat each C: Decodable {
    /// Decodes the family members from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.components = (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}

// MARK: - Helpers

// MARK: - Family Extensions

extension Family where repeat each C: Encodable {
    /// Encodes the components of all family members.
    /// - Parameters:
    ///   - encoder: The encoder to write to.
    /// - Throws: An error if encoding fails.
    public func encodeMembers<E: TopLevelEncoder>(using encoder: inout E) throws -> E.Output {
        let batch = FamilyBatchEncoder(family: self)
        return try encoder.encode(batch)
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

extension Family where repeat each C: Decodable {
    /// Decodes components for new family members.
    /// - Parameters:
    ///   - data: The data to decode from.
    ///   - decoder: The decoder to read from.
    /// - Returns: The newly created entities.
    /// - Throws: An error if decoding fails.
    @discardableResult
    public func decodeMembers<D: TopLevelDecoder>(from data: D.Input, using decoder: inout D) throws -> [Entity] {
        let batch = try decoder.decode(FamilyBatchDecoder<repeat each C>.self, from: data)
        var entities: [Entity] = []
        for components in batch.componentsList {
            let entity = nexus.createEntity(with: repeat each components)
            entities.append(entity)
        }
        return entities
    }
    
    /// Decodes components from a keyed container using a strategy.
    public static func decode(
        from container: KeyedDecodingContainer<DynamicCodingKey>,
        using strategy: CodingStrategy
    ) throws -> (repeat each C) {
        return (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}

// MARK: - Internal Batch Types

fileprivate struct FamilyBatchEncoder<each C: Component>: Encodable where repeat each C: Encodable {
    let family: Family<repeat each C>
    
    func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var container = encoder.unkeyedContainer()
        
        for entityId in family.memberIds {
            // Retrieve components
            let components = (repeat family.nexus.get(unsafe: entityId) as (each C))
            
            // Encode into nested keyed container
            var nestedContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self)
            _ = (repeat try nestedContainer.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
        }
    }
}

fileprivate struct FamilyBatchDecoder<each C: Component>: Decodable where repeat each C: Decodable {
    let componentsList: [(repeat each C)]
    
    init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var container = try decoder.unkeyedContainer()
        var list: [(repeat each C)] = []
        
        while !container.isAtEnd {
            let nestedContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self)
            let components = (repeat try nestedContainer.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
            list.append(components)
        }
        self.componentsList = list
    }
}
#endif
