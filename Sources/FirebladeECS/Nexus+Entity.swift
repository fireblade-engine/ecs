//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// Creates a new entity with a unique identifier.
    /// - Returns: The newly created entity.
    @discardableResult
    public func createEntity() -> Entity {
        let entityId: EntityIdentifier = entityIdGenerator.nextId()
        componentIdsByEntity[entityId] = []
        delegate?.nexusEvent(EntityCreated(entityId: entityId))
        return Entity(nexus: self, id: entityId)
    }

    /// Creates a new entity with the provided components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The newly created entity.
    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        let newEntity = createEntity()
        assign(components: components, to: newEntity.identifier)
        return newEntity
    }

    /// Creates a new entity with a collection of components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The newly created entity.
    @discardableResult
    public func createEntity(with components: some Collection<Component>) -> Entity {
        let entity = createEntity()
        assign(components: components, to: entity.identifier)
        return entity
    }

    /// Number of entities in nexus.
    public var numEntities: Int {
        componentIdsByEntity.keys.count
    }

    /// Creates an iterator over all entities in the nexus.
    ///
    /// Entity order is not guaranteed to stay the same over iterations.
    public func makeEntitiesIterator() -> EntitiesIterator {
        EntitiesIterator(nexus: self)
    }

    /// Checks if an entity exists in the Nexus.
    /// - Parameter entityId: The identifier of the entity to check.
    /// - Returns: `true` if the entity exists; otherwise, `false`.
    public func exists(entity entityId: EntityIdentifier) -> Bool {
        componentIdsByEntity.keys.contains(entityId)
    }

    /// Retrieves an entity instance for a given identifier.
    ///
    /// - Parameter entityId: The entity identifier.
    /// - Returns: An `Entity` instance associated with the identifier.
    public func entity(from entityId: EntityIdentifier) -> Entity {
        Entity(nexus: self, id: entityId)
    }

    /// Destroys an entity and removes it from the Nexus.
    ///
    /// - Parameter entity: The entity to destroy.
    /// - Returns: `true` if the entity was successfully destroyed; otherwise, `false`.
    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        destroy(entityId: entity.identifier)
    }

    /// Destroys an entity by its identifier.
    ///
    /// This removes all components associated with the entity and releases its identifier for reuse.
    /// - Parameter entityId: The identifier of the entity to destroy.
    /// - Returns: `true` if the entity was found and destroyed; otherwise, `false`.
    @discardableResult
    public func destroy(entityId: EntityIdentifier) -> Bool {
        guard componentIdsByEntity.keys.contains(entityId) else {
            delegate?.nexusNonFatalError("EntityRemove failure: no entity \(entityId) to remove")
            return false
        }

        if removeAll(components: entityId) {
            update(familyMembership: entityId)
        }

        if let index = componentIdsByEntity.index(forKey: entityId) {
            componentIdsByEntity.remove(at: index)
        }

        entityIdGenerator.markUnused(entityId: entityId)

        delegate?.nexusEvent(EntityDestroyed(entityId: entityId))
        return true
    }
}

// MARK: - entities iterator

extension Nexus {
    /// An iterator over the entities managed by the Nexus.
    public struct EntitiesIterator: IteratorProtocol {
        private var iterator: AnyIterator<Entity>

        /// Creates a new iterator for the given Nexus.
        /// - Parameter nexus: The nexus to iterate over.
        @usableFromInline
        init(nexus: Nexus) {
            var iter = nexus.componentIdsByEntity.keys.makeIterator()
            iterator = AnyIterator {
                guard let entityId = iter.next() else {
                    return nil
                }
                return Entity(nexus: nexus, id: entityId)
            }
        }

        /// Advances to the next entity and returns it, or `nil` if no next entity exists.
        /// - Returns: The next entity in the sequence, or `nil`.
        public func next() -> Entity? {
            iterator.next()
        }
    }
}

extension Nexus.EntitiesIterator: LazySequenceProtocol {}
extension Nexus.EntitiesIterator: Sequence {}
