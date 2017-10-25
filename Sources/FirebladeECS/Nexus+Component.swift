//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	public func has(component: ComponentIdentifier, entity: EntityIdentifier) -> Bool {
		let hash: EntityComponentHash = component.hashValue(using: entity.index)
		return has(hash)
	}

	fileprivate func has(_ hash: EntityComponentHash) -> Bool {
		return componentIndexByEntityComponentHash[hash] != nil
	}

	public func count(components entityId: EntityIdentifier) -> Int {
		switch componentIdsByEntity[entityId.index] {
		case .some(let componentIds):
			return componentIds.count
		case .none:
			return 0
		}
	}

	public func assign(component: Component, to entity: Entity) {
		let componentId = component.identifier
		let entityIdx = entity.identifier.index
		let hash: EntityComponentHash = componentId.hashValue(using: entityIdx)
		/// test if component is already assigned
		guard !has(hash) else {
			report("ComponentAdd collision: \(entityIdx) already has a component \(component)")
			// TODO: replace component?! copy properties?!
			return
		}
		var newComponentIndex: ComponentIndex = ComponentIndex.invalid
		if componentsByType[componentId] != nil {
			newComponentIndex = componentsByType[componentId]!.count // TODO: get next free index
			componentsByType[componentId]!.append(component) // Amortized O(1)
		} else {
			newComponentIndex = 0
			componentsByType[componentId] = UniformComponents(arrayLiteral: component)
		}

		// assigns the component id to the entity id
		if componentIdsByEntity[entityIdx] != nil {
			let endIndex: Int = componentIdsByEntity[entityIdx]!.count
			componentIdsByEntity[entityIdx]!.append(componentId) // Amortized O(1)
			componentIdsByEntityLookup[hash] = endIndex
		} else {
			componentIdsByEntity[entityIdx] = ComponentIdentifiers(arrayLiteral: componentId)
			componentIdsByEntityLookup[hash] = 0
		}

		// assign entity / component to index
		componentIndexByEntityComponentHash[hash] = newComponentIndex

		// FIXME: this is costly for many families
		let entityId: EntityIdentifier = entity.identifier
		for (_, family) in familiyByTraitHash {
			update(membership: family, for: entityId)
		}

		notify(ComponentAdded(component: componentId, to: entity.identifier))
	}

	public func assign<C>(component: C, to entity: Entity) where C: Component {
		assign(component: component, to: entity)
	}

	public func get(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
		let hash: EntityComponentHash = componentId.hashValue(using: entityId.index)
		guard let componentIdx: ComponentIndex = componentIndexByEntityComponentHash[hash] else { return nil }
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else { return nil }
		return uniformComponents[componentIdx]
	}

	public func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
		let componentId: ComponentIdentifier = C.identifier
		let hash: EntityComponentHash = componentId.hashValue(using: entityId)
		return get(componentId: componentId, hash: hash)
	}

	fileprivate func get<C>(componentId: ComponentIdentifier, hash: EntityComponentHash) -> C? where C: Component {
		guard let componentIdx: ComponentIndex = componentIndexByEntityComponentHash[hash] else { return nil }
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else { return nil }
		return uniformComponents[componentIdx] as? C
	}

	public func get(components entityId: EntityIdentifier) -> ComponentIdentifiers? {
		return componentIdsByEntity[entityId.index]
	}

	@discardableResult
	public func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
		let hash: EntityComponentHash = componentId.hashValue(using: entityId.index)

		// MARK: delete component instance
		guard let componentIdx: ComponentIndex = componentIndexByEntityComponentHash.removeValue(forKey: hash) else {
			report("ComponentRemove failure: entity \(entityId) has no component \(componentId)")
			return false
		}

		guard componentsByType[componentId]?.remove(at: componentIdx) != nil else {
			assert(false, "ComponentRemove failure: no component instance for \(componentId) with the given index \(componentIdx)")
			report("ComponentRemove failure: no component instance for \(componentId) with the given index \(componentIdx)")
			return false
		}

		// MARK: unassign component
		guard let removeIndex: ComponentIdsByEntityIndex = componentIdsByEntityLookup.removeValue(forKey: hash) else {
			assert(false, "ComponentRemove failure: no component found to be removed")
			report("ComponentRemove failure: no component found to be removed")
			return false
		}

		guard componentIdsByEntity[entityId.index]?.remove(at: removeIndex) != nil else {
			assert(false, "ComponentRemove failure: nothing was removed")
			report("ComponentRemove failure: nothing was removed")
			return false
		}

		// relocate remaining indices pointing in the componentsByEntity map
		if let remainingComponents: ComponentIdentifiers = componentIdsByEntity[entityId.index] {
			// FIXME: may be expensive but is cheap for small entities
			for (index, compId) in remainingComponents.enumerated() {
				let cHash: EntityComponentHash = compId.hashValue(using: entityId.index)
				componentIdsByEntityLookup[cHash] = index
			}
		}

		// FIXME: this is costly for many families
		for (_, family) in familiyByTraitHash {
			update(membership: family, for: entityId)
		}

		notify(ComponentRemoved(component: componentId, from: entityId))
		return true
	}

	@discardableResult
	public func clear(componentes entityId: EntityIdentifier) -> Bool {
		guard let allComponents: ComponentIdentifiers = get(components: entityId) else {
			report("clearing components form entity \(entityId) with no components")
			return true
		}
		let removedAll: Bool = allComponents.reduce(true, { $0 && remove(component: $1, from: entityId) })
		return removedAll
	}

}
