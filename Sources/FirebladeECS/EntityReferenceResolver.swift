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
///
/// A resolver can be created before its target nexus exists and be bound later via ``bind(to:)``.
/// This allows decoding entry points that create the target nexus themselves to use the
/// resolver supplied through the decoder's read-only `userInfo`.
public final class EntityReferenceResolver {
    /// The nexus the resolved entities belong to, once bound.
    private var boundNexus: Nexus?

    /// The mapping from encoded (source) entity identifiers to target entity identifiers.
    public private(set) var mapping: [EntityIdentifier: EntityIdentifier]

    /// Creates a new resolver that is not yet bound to a target nexus.
    /// - Parameter mapping: The initial mapping from source to target entity identifiers.
    public init(mapping: [EntityIdentifier: EntityIdentifier]) {
        self.mapping = mapping
    }

    /// Creates a new resolver bound to a target nexus.
    /// - Parameters:
    ///   - nexus: The nexus the resolved entities belong to.
    ///   - mapping: The initial mapping from source to target entity identifiers.
    public convenience init(nexus: Nexus, mapping: [EntityIdentifier: EntityIdentifier]) {
        self.init(mapping: mapping)
        bind(to: nexus)
    }

    /// Binds the resolver to the nexus the resolved entities belong to, replacing a previous binding.
    /// - Parameter nexus: The target nexus.
    /// - Complexity: O(1)
    public func bind(to nexus: Nexus) {
        boundNexus = nexus
    }

    /// Returns the nexus the resolved entities belong to.
    /// - Returns: The bound target nexus.
    /// - Throws: ``EntityReferenceError/unboundResolver`` if the resolver is not bound.
    /// - Complexity: O(1)
    public func targetNexus() throws -> Nexus {
        guard let boundNexus else {
            throw EntityReferenceError.unboundResolver
        }
        return boundNexus
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
    /// - Throws: ``EntityReferenceError/unboundResolver`` if the resolver is not bound,
    ///   ``EntityReferenceError/unresolved(_:)`` if the identifier is not mapped.
    /// - Complexity: O(1)
    public func resolve(_ source: EntityIdentifier) throws -> Entity {
        let nexus = try targetNexus()
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
