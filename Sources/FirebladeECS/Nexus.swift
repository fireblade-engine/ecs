//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// Main entity storage.
    /// Entities are tightly packed by EntityIdentifier.
    @usableFromInline final var entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Id>

    /// Entity ids that are currently not used.
    @usableFromInline final var freeEntities: [EntityIdentifier]

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
    @usableFromInline final var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Id>]

    public final weak var delegate: NexusEventDelegate?

    public convenience init() {
        self.init(entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Id>(),
                  componentsByType: [:],
                  componentsByEntity: [:],
                  freeEntities: [],
                  familyMembersByTraits: [:],
                  childrenByParentEntity: [:])
    }

    internal init(entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Id>,
                  componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>],
                  componentsByEntity: [EntityIdentifier: Set<ComponentIdentifier>],
                  freeEntities: [EntityIdentifier],
                  familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Id>],
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

    @available(swift, deprecated: 0.11.2)
    public static var knownUniqueComponentTypes: Set<ComponentIdentifier> {
        Set<ComponentIdentifier>(stableComponentIdentifierMap.keys.map { ComponentIdentifier(hash: $0) })
    }
}

// MARK: - centralized component identifier mapping
extension Nexus {
    internal static var stableComponentIdentifierMap: [ComponentIdentifier.Hash: ComponentIdentifier.StableId] = [:]

    internal static func makeOrGetComponentId<C>(_ componentType: C.Type) -> ComponentIdentifier.Hash where C: Component {
        /// object identifier hash (only stable during runtime) - arbitrary hash is ok.
        let objIdHash = ObjectIdentifier(componentType).hashValue
        // if we do not know this component type yet - we register a stable identifier generator for it.
        if stableComponentIdentifierMap[objIdHash] == nil {
            let string = String(describing: C.self)
            let stableHash = StringHashing.singer_djb2(string)
            stableComponentIdentifierMap[objIdHash] = stableHash
        }
        return objIdHash
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}
