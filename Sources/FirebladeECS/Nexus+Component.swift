//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	public var numComponents: Int {
		var count = 0
		for (_, uniformComps) in componentsByType {
			count += uniformComps.count
		}
		return count
	}

	public func has(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> Bool {
		guard let uniforms = componentsByType[componentId] else { return false }
		return uniforms.has(entityIdx)
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
		guard !has(componentId: componentId, entityIdx: entityIdx) else {
			report("ComponentAdd collision: \(entityIdx) already has a component \(component)")
			// TODO: replace component?! copy properties?!
			return
		}
		if componentsByType[componentId] == nil {
			componentsByType[componentId] = UniformComponents()
		}
		componentsByType[componentId]!.add(component, at: entityIdx)

		// assigns the component id to the entity id
		if componentIdsByEntity[entityIdx] != nil {
			let endIndex: Int = componentIdsByEntity[entityIdx]!.count
			componentIdsByEntity[entityIdx]!.append(componentId) // Amortized O(1)
			componentIdsByEntityLookup[hash] = endIndex
		} else {
			componentIdsByEntity[entityIdx] = ComponentIdentifiers(arrayLiteral: componentId)
			componentIdsByEntityLookup[hash] = 0
		}

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
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else { return nil }
		return uniformComponents.get(at: entityId.index) as? Component
	}

	public func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
		let componentId: ComponentIdentifier = C.identifier
		return get(componentId: componentId, entityIdx: entityId.index)
	}

	fileprivate func get<C>(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> C? where C: Component {
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else { return nil }
		return uniformComponents.get(at: entityIdx) as? C
	}

	public func get(components entityId: EntityIdentifier) -> ComponentIdentifiers? {
		return componentIdsByEntity[entityId.index]
	}

	@discardableResult
	public func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
		let entityIdx: EntityIndex = entityId.index
		let hash: EntityComponentHash = componentId.hashValue(using: entityIdx)

		// MARK: delete component instance
		componentsByType[componentId]?.remove(at: entityIdx)

		// MARK: unassign component
		guard let removeIndex: ComponentIdsByEntityIndex = componentIdsByEntityLookup.removeValue(forKey: hash) else {
			report("ComponentRemove failure: no component found to be removed")
			return false
		}

		guard componentIdsByEntity[entityIdx]?.remove(at: removeIndex) != nil else {
			assert(false, "ComponentRemove failure: nothing was removed")
			report("ComponentRemove failure: nothing was removed")
			return false
		}

		// relocate remaining indices pointing in the componentsByEntity map
		if let remainingComponents: ComponentIdentifiers = componentIdsByEntity[entityIdx] {
			// FIXME: may be expensive but is cheap for small entities
			for (index, compId) in remainingComponents.enumerated() {
				let cHash: EntityComponentHash = compId.hashValue(using: entityIdx)
				assert(cHash != hash)
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
