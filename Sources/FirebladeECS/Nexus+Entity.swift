//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	public var entities: [Entity] {
		return entityStorage.filter { isValid(entity: $0.identifier) }
	}

	fileprivate func nextEntityIdx() -> EntityIndex {
		guard let nextReused: EntityIdentifier = freeEntities.popLast() else {
			return entityStorage.count
		}
		return nextReused.index
	}

	public func create(entity name: String? = nil) -> Entity {
		let newEntityIndex: EntityIndex = nextEntityIdx()
		let newEntityIdentifier: EntityIdentifier = newEntityIndex.identifier
		if entityStorage.count > newEntityIndex {
			let reusedEntity: Entity = entityStorage[newEntityIndex]
			assert(reusedEntity.identifier == EntityIdentifier.invalid, "Stil valid entity \(reusedEntity)")
			reusedEntity.identifier = newEntityIdentifier
			reusedEntity.name = name
			notify(EntityCreated(entityId: newEntityIdentifier))
			return reusedEntity
		} else {
			let newEntity = Entity(nexus: self, id: newEntityIdentifier, name: name)
			entityStorage.insert(newEntity, at: newEntityIndex)
			notify(EntityCreated(entityId: newEntityIdentifier))
			return newEntity
		}
	}

	/// Number of entities in nexus.
	public var numEntities: Int {
		return entityStorage.count - freeEntities.count
	}

	func isValid(entity: Entity) -> Bool {
		return isValid(entity: entity.identifier)
	}

	func isValid(entity entitiyId: EntityIdentifier) -> Bool {
		return entitiyId != EntityIdentifier.invalid &&
			entitiyId.index >= 0 &&
			entitiyId.index < entityStorage.count
	}

	public func has(entity entityId: EntityIdentifier) -> Bool {
		return isValid(entity: entityId)
	}

	public func get(entity entityId: EntityIdentifier) -> Entity {
		return entityStorage[entityId.index]
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
		entityStorage[entityId.index] = invalidEntity

		freeEntities.append(entityId)

		for (_, family) in familiesByTraitHash {
			update(membership: family, for: entityId)
		}

		notify(EntityDestroyed(entityId: entityId))
		return true
	}

}
