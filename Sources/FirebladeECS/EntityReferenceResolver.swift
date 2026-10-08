//
//  EntityReferenceResolver.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Resolves encoded entity identifiers to entities of a target nexus while decoding.
///
/// Entities are handles into a ``Nexus`` and can therefore not be decoded on their own.
/// Provide a resolver via `decoder.userInfo[.nexusEntityResolver]` to decode components
/// that reference other entities. The resolver maps every encoded (source) identifier
/// to the identifier of the corresponding entity in the target nexus.
public final class EntityReferenceResolver {
    /// The nexus the resolved entities belong to.
    public let nexus: Nexus

    /// The mapping from encoded (source) entity identifiers to target entity identifiers.
    public private(set) var mapping: [EntityIdentifier: EntityIdentifier]

    /// Creates a new resolver.
    /// - Parameters:
    ///   - nexus: The nexus the resolved entities belong to.
    ///   - mapping: The initial mapping from source to target entity identifiers.
    public init(nexus: Nexus, mapping: [EntityIdentifier: EntityIdentifier]) {
        self.nexus = nexus
        self.mapping = mapping
    }

    /// Maps a source entity identifier to a target entity identifier.
    /// - Parameters:
    ///   - source: The encoded entity identifier.
    ///   - target: The identifier of the entity in the target nexus.
    /// - Complexity: O(1)
    public func map(_ source: EntityIdentifier, to target: EntityIdentifier) {
        mapping[source] = target
    }

    /// Resolves an encoded entity identifier to an entity of the target nexus.
    /// - Parameter source: The encoded entity identifier.
    /// - Returns: The mapped entity in the target nexus.
    /// - Throws: ``EntityReferenceError/unresolved(_:)`` if the identifier is not mapped.
    /// - Complexity: O(1)
    public func resolve(_ source: EntityIdentifier) throws -> Entity {
        guard let target = mapping[source] else {
            throw EntityReferenceError.unresolved(source)
        }
        return Entity(nexus: nexus, id: target)
    }
}

extension EntityReferenceResolver: @unchecked Sendable {}

extension CodingUserInfoKey {
    /// A user info key for providing an ``EntityReferenceResolver`` while decoding entities.
    public static let nexusEntityResolver = CodingUserInfoKey(rawValue: "nexusEntityResolver").unsafelyUnwrapped
}
