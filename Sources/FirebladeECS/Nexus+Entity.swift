//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	private func nextEntityIdx() -> EntityIndex {
		guard let nextReused: EntityIdentifier = freeEntities.popLast() else {
			return entityStorage.count
		}
		return nextReused.index
	}

	public func create(entity name: String? = nil) -> Entity {
		let newEntityIndex: EntityIndex = nextEntityIdx()
		let newEntityIdentifier: EntityIdentifier = newEntityIndex.identifier

        let newEntity: Entity = Entity(nexus: self, id: newEntityIdentifier, name: name)
		entityStorage.add(newEntity, at: newEntityIndex)
		notify(EntityCreated(entityId: newEntityIdentifier))
		return newEntity
	}

	/// Number of entities in nexus.
	public var numEntities: Int {
		return entityStorage.count
	}

	public func has(entity entityId: EntityIdentifier) -> Bool {
		return entityStorage.has(entityId.index)
	}

	public func get(entity entityId: EntityIdentifier) -> Entity? {
		return entityStorage.get(at: entityId.index)
	}

	@discardableResult
	public func destroy(entity: Entity) -> Bool {
		let entityId: EntityIdentifier = entity.identifier
		let entityIdx: EntityIndex = entityId.index

		guard entityStorage.remove(at: entityIdx) else {
			report("EntityRemove failure: no entity \(entityId) to remove")
			return false
		}

		let cleared: Bool = clear(componentes: entityId)
		assert(cleared, "Could not clear all components form entity \(entityId)")

		freeEntities.append(entityId)

		update(familyMembership: entityId)

		notify(EntityDestroyed(entityId: entityId))
		return true
	}

}
