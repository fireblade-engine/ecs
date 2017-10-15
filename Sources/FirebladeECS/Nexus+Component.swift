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
		switch componentIdsByEntityIdx[entityId.index] {
		case .some(let componentIds):
			return componentIds.count
		case .none:
			return 0
		}
	}

	public func assign<C>(component: C, to entityId: EntityIdentifier) where C: Component {
		let componentId = C.identifier
		let entityIdx = entityId.index
		let hash: EntityComponentHash = componentId.hashValue(using: entityIdx)
		assert(!has(hash), "ComponentAdd collision: \(entityId) already has a component \(component)")
		var newComponentIndex: ComponentIndex = ComponentIndex.invalid
		if componentsByType[componentId] != nil {
			newComponentIndex = componentsByType[componentId]!.count // TODO: get next free index
			componentsByType[componentId]!.insert(component, at: newComponentIndex)
		} else {
			newComponentIndex = 0
			componentsByType[componentId] = UniformComponents(arrayLiteral: component)
		}

		if componentIdsByEntityIdx[entityIdx] != nil {
			componentIdsByEntityIdx[entityIdx]!.append(componentId)
		} else {
			componentIdsByEntityIdx[entityIdx] = ComponentIdentifiers()
			componentIdsByEntityIdx[entityIdx]!.append(componentId)
		}


		// assign entity / component to index
		componentIndexByEntityComponentHash[hash] = newComponentIndex

		notify(ComponentAdded(component: componentId, to: entityId))
	}


	public func get<C>(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> C? where C: Component {
		let hash: EntityComponentHash = componentId.hashValue(using: entityId.index)
		return get(hash)
	}

	fileprivate func get<C>(_ hash: EntityComponentHash) -> C? where C: Component {
		let componentId: ComponentIdentifier = C.identifier
		guard let componentIdx: ComponentIndex = componentIndexByEntityComponentHash[hash] else { return nil }
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else { return nil }
		guard let typedComponent: C = uniformComponents[componentIdx] as? C else { return nil }
		return typedComponent
	}

	public func get(components entityId: EntityIdentifier) -> ComponentIdentifiers? {
		return componentIdsByEntityIdx[entityId.index]
	}

	@discardableResult
	public func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
		let hash: EntityComponentHash = componentId.hashValue(using: entityId.index)

		guard let componentIdx: ComponentIndex = componentIndexByEntityComponentHash.removeValue(forKey: hash) else {
			report("ComponentRemove failure: entity \(entityId) has no component \(componentId)")
			return false
		}

		guard componentsByType[componentId]?.remove(at: componentIdx) != nil else {
			assert(false, "ComponentRemove failure: no component instance for \(componentId) with the given index \(componentIdx)")
			report("ComponentRemove failure: no component instance for \(componentId) with the given index \(componentIdx)")
			return false
		}

		// FIXME: this is expensive
		guard let removeIndex: Int = get(components: entityId)?.index(where: { $0 == componentId }) else {
			assert(false, "ComponentRemove failure: no component found to be removed")
			report("ComponentRemove failure: no component found to be removed")
			return false
		}
		guard componentIdsByEntityIdx[entityId.index]?.remove(at: removeIndex) != nil else {
			assert(false, "ComponentRemove failure: nothing was removed")
			report("ComponentRemove failure: nothing was removed")
			return false
		}


		notify(ComponentRemoved(component: componentId, from: entityId))
		return true
	}

	public func clear(componentes entityId: EntityIdentifier) {

		guard let componentIds = get(components: entityId) else { return }

		componentIds.forEach { (componentId: ComponentIdentifier) in
			remove(component: componentId, from: entityId)
		}
	}

}
