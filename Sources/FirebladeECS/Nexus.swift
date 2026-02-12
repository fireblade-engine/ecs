//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// A map of component identifiers to their storage.
    /// - Key: The component identifier (type).
    /// - Value: A contiguous array of components of that type. New component instances are appended.
    @usableFromInline final var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]

    /// A map of entity identifiers to their assigned component identifiers.
    /// - Key: The entity identifier (index).
    /// - Value: A set of component identifiers associated with this entity.
    @usableFromInline final var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]

    /// A map of family traits to the entities that match them.
    /// - Key: The family trait set (component types) that defines the family.
    /// - Value: A sparse set of entity identifiers that are members of this family.
    @usableFromInline final var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>]

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

    /// The delegate for handling nexus events.
    public final weak var delegate: NexusEventDelegate?

    /// Initializes a new Nexus with default settings.
    public convenience init() {
        self.init(componentsByType: [:],
                  componentsByEntity: [:],
                  entityIdGenerator: DefaultEntityIdGenerator(),
                  familyMembersByTraits: [:],
                  codingStrategy: DefaultCodingStrategy())
    }

    /// Initializes a new Nexus with the provided storage and strategies.
    /// - Parameters:
    ///   - componentsByType: The initial storage for components by type.
    ///   - componentsByEntity: The initial mapping of entities to their components.
    ///   - entityIdGenerator: The generator for entity identifiers.
    ///   - familyMembersByTraits: The initial family membership storage.
    ///   - codingStrategy: The strategy for encoding/decoding.
    init(componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>],
         componentsByEntity: [EntityIdentifier: Set<ComponentIdentifier>],
         entityIdGenerator: EntityIdentifierGenerator,
         familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>],
         codingStrategy: CodingStrategy) {
        self.componentsByType = componentsByType
        componentIdsByEntity = componentsByEntity
        self.familyMembersByTraits = familyMembersByTraits
        self.entityIdGenerator = entityIdGenerator
        self.codingStrategy = codingStrategy
    }

    deinit {
        clear()
    }

    /// Clears all data from the Nexus.
    ///
    /// This removes all components, entities, and family memberships.
    public final func clear() {
        componentsByType.removeAll()
        componentIdsByEntity.removeAll()
        familyMembersByTraits.removeAll()
    }
}

extension Nexus: @unchecked Sendable {}

// MARK: - CustomDebugStringConvertible

extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}

// MARK: - default coding strategy

public struct DefaultCodingStrategy: CodingStrategy {
    public init() {}

    public func codingKey<C: Component>(for componentType: C.Type) -> DynamicCodingKey {
        DynamicCodingKey(stringValue: "\(C.self)").unsafelyUnwrapped
    }
}
