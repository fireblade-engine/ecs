//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	public func create(entity name: String? = nil) -> Entity {
		let newEntityIndex: EntityIndex = entities.count // TODO: use free entity index
		let newEntityIdentifier: EntityIdentifier = newEntityIndex.identifier
		let newEntity = Entity(nexus: self, id: newEntityIdentifier, name: name)
		entities.insert(newEntity, at: newEntityIndex)
		notify(EntityCreated(entityId: newEntityIdentifier))
		return newEntity
	}

	public func has(entity entityId: EntityIdentifier) -> Bool {
		return entities.count > entityId.index // TODO: reuse free index

	}

	public func get(entity entityId: EntityIdentifier) -> Entity? {
		guard has(entity: entityId) else { return nil }
		return entities[entityId.index]
	}

	@discardableResult
	public func destroy(entity entityId: EntityIdentifier) -> Bool {
		guard has(entity: entityId) else {
			assert(false, "EntityRemove failure: no entity \(entityId) to remove")
			return false
		}

		clear(componentes: entityId)

		// FIXME: this is wrong since it removes the entity that should be reused
		entities.remove(at: entityId.index)

		notify(EntityDestroyed(entityId: entityId))
		return true
	}


}
