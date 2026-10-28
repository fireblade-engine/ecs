//
//  ComponentCloneContext.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Maps entities to their clones while cloning components.
///
/// References to entities that are part of the clone operation are remapped to the
/// corresponding cloned entities. References to entities outside of the clone operation
/// are kept unchanged.
///
/// Use the `clone(_:)` overloads for every stored property of a ``CloneableComponent``.
/// Values of all other types are returned unchanged, i.e. value types are copied and
/// references to class instances are shared.
public struct ComponentCloneContext {
    /// The nexus the cloned entities belong to.
    public let nexus: Nexus

    /// The mapping from source entity identifiers to the identifiers of their clones.
    public let mapping: [EntityIdentifier: EntityIdentifier]

    /// Creates a new clone context.
    /// - Parameters:
    ///   - nexus: The nexus the cloned entities belong to.
    ///   - mapping: The mapping from source entity identifiers to the identifiers of their clones.
    public init(nexus: Nexus, mapping: [EntityIdentifier: EntityIdentifier]) {
        self.nexus = nexus
        self.mapping = mapping
    }

    /// Returns a value unchanged.
    /// - Parameter value: The value to clone.
    /// - Returns: The same value.
    /// - Complexity: O(1)
    @inlinable
    public func clone<T>(_ value: T) -> T {
        value
    }

    /// Remaps an entity identifier to the identifier of its clone.
    /// - Parameter identifier: The source entity identifier.
    /// - Returns: The identifier of the clone, or the source identifier if it is not part of the clone operation.
    /// - Complexity: O(1)
    public func clone(_ identifier: EntityIdentifier) -> EntityIdentifier {
        guard let mapped = mapping[identifier] else {
            return identifier
        }
        return mapped
    }

    /// Remaps an optional entity identifier to the identifier of its clone.
    /// - Parameter identifier: The source entity identifier.
    /// - Returns: The identifier of the clone, or the source identifier if it is not part of the clone operation.
    /// - Complexity: O(1)
    public func clone(_ identifier: EntityIdentifier?) -> EntityIdentifier? {
        identifier.map { clone($0) }
    }

    /// Remaps an entity to its clone.
    /// - Parameter entity: The source entity.
    /// - Returns: The cloned entity, or the source entity if it is not part of the clone operation.
    /// - Complexity: O(1)
    public func clone(_ entity: Entity) -> Entity {
        guard let mapped = mapping[entity.identifier] else {
            return entity
        }
        return Entity(nexus: nexus, id: mapped)
    }

    /// Remaps an optional entity to its clone.
    /// - Parameter entity: The source entity.
    /// - Returns: The cloned entity, or the source entity if it is not part of the clone operation.
    /// - Complexity: O(1)
    public func clone(_ entity: Entity?) -> Entity? {
        entity.map { clone($0) }
    }

    /// Remaps entities to their clones.
    /// - Parameter entities: The source entities.
    /// - Returns: The remapped entities in the same order.
    /// - Complexity: O(N) where N is the number of entities.
    public func clone(_ entities: [Entity]) -> [Entity] {
        entities.map { clone($0) }
    }

    /// Remaps entity identifiers to the identifiers of their clones.
    /// - Parameter identifiers: The source entity identifiers.
    /// - Returns: The remapped identifiers in the same order.
    /// - Complexity: O(N) where N is the number of identifiers.
    public func clone(_ identifiers: [EntityIdentifier]) -> [EntityIdentifier] {
        identifiers.map { clone($0) }
    }

    /// Remaps a set of entity identifiers to the identifiers of their clones.
    /// - Parameter identifiers: The source entity identifiers.
    /// - Returns: The remapped identifiers.
    /// - Complexity: O(N) where N is the number of identifiers.
    public func clone(_ identifiers: Set<EntityIdentifier>) -> Set<EntityIdentifier> {
        Set(identifiers.map { clone($0) })
    }

    /// Remaps the entity values of a dictionary to their clones.
    /// - Parameter entities: The dictionary with source entities as values.
    /// - Returns: A dictionary with the same keys and remapped entities.
    /// - Complexity: O(N) where N is the number of entries.
    public func clone<Key>(_ entities: [Key: Entity]) -> [Key: Entity] {
        entities.mapValues { clone($0) }
    }
}
