//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	fileprivate func nextEntityIdx() -> EntityIndex {
		guard let nextReused: EntityIdentifier = freeEntities.popLast() else {
			return entities.count
		}
		return nextReused.index
	}

	public func create(entity name: String? = nil) -> Entity {
		let newEntityIndex: EntityIndex = nextEntityIdx()
		let newEntityIdentifier: EntityIdentifier = newEntityIndex.identifier
		if entities.count > newEntityIndex {
			let reusedEntity: Entity = entities[newEntityIndex]
			assert(reusedEntity.identifier == EntityIdentifier.invalid, "Stil valid entity \(reusedEntity)")
			reusedEntity.identifier = newEntityIdentifier
			reusedEntity.name = name
			notify(EntityCreated(entityId: newEntityIdentifier))
			return reusedEntity
		} else {
			let newEntity = Entity(nexus: self, id: newEntityIdentifier, name: name)
			entities.insert(newEntity, at: newEntityIndex)
			notify(EntityCreated(entityId: newEntityIdentifier))
			return newEntity
		}
	}

	/// Number of entities in nexus.
	public var count: Int {
		return entities.count - freeEntities.count
	}

	func isValid(entity: Entity) -> Bool {
		return isValid(entity: entity.identifier)
	}

	func isValid(entity entitiyId: EntityIdentifier) -> Bool {
		return entitiyId != EntityIdentifier.invalid &&
			entitiyId.index >= 0 &&
			entitiyId.index < entities.count
	}

	public func has(entity entityId: EntityIdentifier) -> Bool {
		return isValid(entity: entityId)
	}

	public func get(entity entityId: EntityIdentifier) -> Entity? {
		Log.info("GETTING ENTITY: \(entityId)")
		guard has(entity: entityId) else { return nil }
		return entities[entityId.index]
	}

	@discardableResult
	public func destroy(entity: Entity) -> Bool {
		let entityId: EntityIdentifier = entity.identifier
		guard has(entity: entityId) else {
			report("EntityRemove failure: no entity \(entityId) to remove")
			return false
		}

		let cleared: Bool = clear(componentes: entityId)
		assert(cleared, "Could not clear all components form entity \(entityId)")

		entity.invalidate()

		// replace with "new" invalid entity to keep capacity of array
		let invalidEntity = Entity(nexus: self, id: EntityIdentifier.invalid)
		entities[entityId.index] = invalidEntity

		freeEntities.append(entityId)

		notify(EntityDestroyed(entityId: entityId))
		return true
	}

}
