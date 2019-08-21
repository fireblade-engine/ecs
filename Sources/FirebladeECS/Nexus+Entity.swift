//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    @inlinable internal func nextEntityId() -> EntityIdentifier {
        guard let nextReused: EntityIdentifier = freeEntities.popLast() else {
            return EntityIdentifier(UInt32(entityStorage.count))
        }
        return nextReused
    }

    @discardableResult
    public func createEntity() -> Entity {
        let newEntityIdentifier: EntityIdentifier = nextEntityId()
        let newEntity = Entity(nexus: self, id: newEntityIdentifier)
        entityStorage.insert(newEntity, at: newEntityIdentifier.index)
        delegate?.nexusEvent(EntityCreated(entityId: newEntityIdentifier))
        return newEntity
    }

    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        let newEntity = createEntity()
        components.forEach { newEntity.assign($0) }
        return newEntity
    }

    /// Number of entities in nexus.
    public var numEntities: Int {
        return entityStorage.count
    }

    public func exists(entity entityId: EntityIdentifier) -> Bool {
        return entityStorage.contains(entityId.index)
    }

    public func get(entity entityId: EntityIdentifier) -> Entity? {
        return entityStorage.get(at: entityId.index)
    }

    public func get(unsafeEntity entityId: EntityIdentifier) -> Entity {
        return entityStorage.get(unsafeAt: entityId.index)
    }

    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        let entityId: EntityIdentifier = entity.identifier

        guard entityStorage.remove(at: entityId.index) != nil else {
            delegate?.nexusNonFatalError("EntityRemove failure: no entity \(entityId) to remove")
            return false
        }

        if removeAll(componentes: entityId) {
            update(familyMembership: entityId)
        }

        freeEntities.append(entityId)

        delegate?.nexusEvent(EntityDestroyed(entityId: entityId))
        return true
    }
}
