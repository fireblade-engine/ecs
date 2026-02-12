//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    @discardableResult
    public func createEntity() -> Entity {
        let entityId: EntityIdentifier = entityIdGenerator.nextId()
        componentIdsByEntity[entityId] = []
        delegate?.nexusEvent(EntityCreated(entityId: entityId))
        return Entity(nexus: self, id: entityId)
    }

    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        let newEntity = createEntity()
        assign(components: components, to: newEntity.identifier)
        return newEntity
    }

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

    public func exists(entity entityId: EntityIdentifier) -> Bool {
        componentIdsByEntity.keys.contains(entityId)
    }

    public func entity(from entityId: EntityIdentifier) -> Entity {
        Entity(nexus: self, id: entityId)
    }

    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        destroy(entityId: entity.identifier)
    }

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

        public func next() -> Entity? {
            iterator.next()
        }
    }
}

extension Nexus.EntitiesIterator: LazySequenceProtocol {}
extension Nexus.EntitiesIterator: Sequence {}
