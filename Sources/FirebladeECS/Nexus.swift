//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// Main entity storage.
    /// Entities are tightly packed by EntityIdentifier.
    @usableFromInline final var entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>

    /// - Key: ComponentIdentifier aka component type.
    /// - Value: Array of component instances of same type (uniform).
    ///          New component instances are appended.
    @usableFromInline final var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]

    /// - Key: EntityIdentifier aka entity index
    /// - Value: Set of unique component types (ComponentIdentifier).
    ///          Each element is a component identifier associated with this entity.
    @usableFromInline final var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]

    /// - Key: FamilyTraitSet aka component types that make up one distinct family.
    /// - Value: Tightly packed EntityIdentifiers that represent the association of an entity to the family.
    @usableFromInline final var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>]

    /// The entity identifier generator responsible for providing unique ids for entities during runtime.
    ///
    /// Provide a custom implementation prior to entity creation.
    /// Defaults to `DefaultEntityIdGenerator`.
    public final var entityIdGenerator: EntityIdentifierGenerator

    /// The coding strategy used to encode/decode entities from/into families.
    ///
    /// Provide a custom implementation prior to encoding/decoding.
    /// Defaults to `DefaultCodingStrategy`.
    public final var codingStrategy: CodingStrategy

    public final weak var delegate: NexusEventDelegate?

    public convenience init() {
        self.init(entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>(),
                  componentsByType: [:],
                  componentsByEntity: [:],
                  entityIdGenerator: DefaultEntityIdGenerator(),
                  familyMembersByTraits: [:],
                  codingStrategy: DefaultCodingStrategy())
    }

    internal init(entityStorage: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>,
                  componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>],
                  componentsByEntity: [EntityIdentifier: Set<ComponentIdentifier>],
                  entityIdGenerator: EntityIdentifierGenerator,
                  familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>],
                  codingStrategy: CodingStrategy) {
        self.entityStorage = entityStorage
        self.componentsByType = componentsByType
        self.componentIdsByEntity = componentsByEntity
        self.familyMembersByTraits = familyMembersByTraits
        self.entityIdGenerator = entityIdGenerator
        self.codingStrategy = codingStrategy
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
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}

// MARK: - default coding strategy
public struct DefaultCodingStrategy: CodingStrategy {
    public init() { }

    public func codingKey<C>(for componentType: C.Type) -> DynamicCodingKey where C: Component {
        DynamicCodingKey(stringValue: "\(C.self)").unsafelyUnwrapped
    }
}
