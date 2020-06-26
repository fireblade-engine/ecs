//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// Main entity storage.
    /// Entities are tightly packed by EntityIdentifier.
    @usableFromInline final var entityStorage: UnorderedSparseSet<EntityIdentifier>

    /// Entity ids that are currently not used.
    let entityIdGenerator: EntityIdentifierGenerator

    /// - Key: ComponentIdentifier aka component type.
    /// - Value: Array of component instances of same type (uniform).
    ///          New component instances are appended.
    @usableFromInline final var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]

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
                  entityIdGenerator: EntityIdentifierGenerator(),
                  familyMembersByTraits: [:],
                  childrenByParentEntity: [:])
    }

    internal init(entityStorage: UnorderedSparseSet<EntityIdentifier>,
                  componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>],
                  componentsByEntity: [EntityIdentifier: Set<ComponentIdentifier>],
                  entityIdGenerator: EntityIdentifierGenerator,
                  familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier>],
                  childrenByParentEntity: [EntityIdentifier: Set<EntityIdentifier>]) {
        self.entityStorage = entityStorage
        self.componentsByType = componentsByType
        self.componentIdsByEntity = componentsByEntity
        self.familyMembersByTraits = familyMembersByTraits
        self.childrenByParentEntity = childrenByParentEntity
        self.entityIdGenerator = entityIdGenerator
    }

    deinit {
        clear()
    }

    public final func clear() {
        entityStorage.forEach { destroy(entityId: $0) }
        entityStorage.removeAll()
        componentsByType.removeAll()
        componentIdsByEntity.removeAll()
        familyMembersByTraits.removeAll()
        childrenByParentEntity.removeAll()
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}
