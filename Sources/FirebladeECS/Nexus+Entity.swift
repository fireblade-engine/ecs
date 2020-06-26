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
        entityStorage.insert(entityId, at: entityId.id)
        delegate?.nexusEvent(EntityCreated(entityId: entityId))
        return Entity(nexus: self, id: entityId)
    }

    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        let newEntity = createEntity()
        components.forEach { newEntity.assign($0) }
        return newEntity
    }

    /// Number of entities in nexus.
    public var numEntities: Int {
        entityStorage.count
    }

    public func exists(entity entityId: EntityIdentifier) -> Bool {
        entityStorage.contains(entityId.id)
    }

    public func get(entity entityId: EntityIdentifier) -> Entity? {
        guard let id = entityStorage.get(at: entityId.id) else {
            return nil
        }
        return Entity(nexus: self, id: id)
    }

    public func get(unsafeEntity entityId: EntityIdentifier) -> Entity {
        Entity(nexus: self, id: entityStorage.get(unsafeAt: entityId.id))
    }

    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        self.destroy(entityId: entity.identifier)
    }

    @discardableResult
    public func destroy(entityId: EntityIdentifier) -> Bool {
        guard entityStorage.remove(at: entityId.id) != nil else {
            delegate?.nexusNonFatalError("EntityRemove failure: no entity \(entityId) to remove")
            return false
        }

        removeAllChildren(from: entityId)

        if removeAll(components: entityId) {
            update(familyMembership: entityId)
        }

        entityIdGenerator.freeId(entityId)

        delegate?.nexusEvent(EntityDestroyed(entityId: entityId))
        return true
    }
}
