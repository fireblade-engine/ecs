//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// Static version string.
    public static let version: String = "1.0.0"

    /// Main entity storage.
    /// Entities are tightly packed by EntityIdentifier.
    @usableFromInline final var entityStorage: UnorderedSparseSet<EntityIdentifier>

    /// Entity ids that are currently not used.
    @usableFromInline final var freeEntities: [EntityIdentifier]

    /// - Key: ComponentIdentifier aka component type.
    /// - Value: Array of component instances of same type (uniform).
    ///          New component instances are appended.
    @usableFromInline final var componentsByType: [ComponentIdentifier: UnorderedSparseSet<Component>]

    /// - Key: EntityIdentifier aka entity index
    /// - Value: Set of unique component types (ComponentIdentifier).
    ///          Each element is a component identifier associated with this entity.
    @usableFromInline final var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]

    /// - Key: A parent entity id.
    /// - Value: Adjacency Set of all associated children.
    @usableFromInline final var childrenByParentEntity: [EntityIdentifier: Set<EntityIdentifier>]

    /// - Key: FamilyTraitSet aka component types that make up one distinct family.
    /// - Value: Tightly packed EntityIdentifiers that represent the association of an entity to the family.
    @usableFromInline final var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier>]

    public final weak var delegate: NexusEventDelegate?

    public convenience init() {
        self.init(entityStorage: UnorderedSparseSet<EntityIdentifier>(),
                  componentsByType: [:],
                  componentsByEntity: [:],
                  freeEntities: [],
                  familyMembersByTraits: [:],
                  childrenByParentEntity: [:])
    }

    internal init(entityStorage: UnorderedSparseSet<EntityIdentifier>,
                  componentsByType: [ComponentIdentifier: UnorderedSparseSet<Component>],
                  componentsByEntity: [EntityIdentifier: Set<ComponentIdentifier>],
                  freeEntities: [EntityIdentifier],
                  familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier>],
                  childrenByParentEntity: [EntityIdentifier: Set<EntityIdentifier>]) {
        self.entityStorage = entityStorage
        self.componentsByType = componentsByType
        self.componentIdsByEntity = componentsByEntity
        self.freeEntities = freeEntities
        self.familyMembersByTraits = familyMembersByTraits
        self.childrenByParentEntity = childrenByParentEntity
    }

    deinit {
        clear()
    }

    public final func clear() {
        entityStorage.forEach { destroy(entityId: $0) }
        entityStorage.removeAll()
        freeEntities.removeAll()
        componentsByType.removeAll()
        componentIdsByEntity.removeAll()
        familyMembersByTraits.removeAll()
        childrenByParentEntity.removeAll()
    }

    public static var knownUniqueComponentTypes: Set<ComponentIdentifier> {
        return Set<ComponentIdentifier>(componentDecoderMap.keys)
    }

    internal static var componentDecoderMap: [ComponentIdentifier: (Decoder) throws -> Component] = [:]

    /// Register a component type uniquely with the Nexus implementation.
    /// - Parameters:
    ///   - componentType: The component meta type.
    ///   - identifier: The unique identifier.
    internal static func register<C>(component componentType: C.Type, using identifier: ComponentIdentifier) where C: Component {
        precondition(componentDecoderMap[identifier] == nil, "Component type collision: \(identifier) already in use.")
        componentDecoderMap[identifier] = { try C(from: $0) }
    }
}

// MARK: - Errors
extension Nexus {
    public enum Error: Swift.Error {
        case versionMismatch(required: String, provided: String)
    }
}

// MARK: - Equatable
extension Nexus: Equatable {
    @inlinable
    public static func == (lhs: Nexus, rhs: Nexus) -> Bool {
        return lhs.entityStorage == rhs.entityStorage &&
            lhs.componentIdsByEntity == rhs.componentIdsByEntity &&
            lhs.freeEntities == rhs.freeEntities &&
            lhs.familyMembersByTraits == rhs.familyMembersByTraits &&
            lhs.componentsByType.keys == rhs.componentsByType.keys &&
            lhs.childrenByParentEntity == rhs.childrenByParentEntity
        // NOTE: components are not equatable (yet)
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}
