//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	public var numComponents: Int {
		return componentsByType.reduce(0) { return $0 + $1.value.count }
	}

	public func has(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> Bool {
		guard let uniforms = componentsByType[componentId] else {
			return false
		}
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
		let entityId: EntityIdentifier = entity.identifier

		/// test if component is already assigned
		guard !has(componentId: componentId, entityIdx: entityIdx) else {
			// FIXME: this is still open to debate
			// a) we replace the component
			// b) we copy the properties
			// c) we assert fail
			report("ComponentAdd collision: \(entityIdx) already has a component \(component)")
			return
		}

		// add component instances to uniform component stores
		if componentsByType[componentId] == nil {
			componentsByType[componentId] = UniformComponents()
		}
		componentsByType[componentId]?.add(component, at: entityIdx)

		// assigns the component id to the entity id
		if componentIdsByEntity[entityIdx] == nil {
			componentIdsByEntity[entityIdx] = SparseComponentIdentifierSet()
		}
		componentIdsByEntity[entityIdx]?.add(componentId, at: componentId.hashValue)

		// FIXME: iterating all families is costly for many families
		for (_, family) in familiesByTraitHash {
			update(membership: family, for: entityId)
		}

		notify(ComponentAdded(component: componentId, toEntity: entity.identifier))
	}

	public func assign<C>(component: C, to entity: Entity) where C: Component {
		assign(component: component, to: entity)
	}

	public func get(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else {
			return nil
		}
		return uniformComponents.get(at: entityId.index) as? Component
	}

	public func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
		let componentId: ComponentIdentifier = C.identifier
		return get(componentId: componentId, entityIdx: entityId.index)
	}

	private func get<C>(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> C? where C: Component {
		guard let uniformComponents: UniformComponents = componentsByType[componentId] else {
			return nil
		}
		return uniformComponents.get(at: entityIdx) as? C
	}

	public func get(components entityId: EntityIdentifier) -> SparseComponentIdentifierSet? {
		return componentIdsByEntity[entityId.index]
	}

	@discardableResult
	public func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
		let entityIdx: EntityIndex = entityId.index
		//let hash: EntityComponentHash = componentId.hashValue(using: entityIdx)

		// delete component instance
		componentsByType[componentId]?.remove(at: entityIdx)
		// unasign component from entity
		componentIdsByEntity[entityIdx]?.remove(at: componentId.hashValue)

		// FIXME: iterating all families is costly for many families
		for (_, family) in familiesByTraitHash {
			update(membership: family, for: entityId)
		}

		notify(ComponentRemoved(component: componentId, from: entityId))
		return true
	}

	@discardableResult
	public func clear(componentes entityId: EntityIdentifier) -> Bool {
		guard let allComponents = get(components: entityId) else {
			report("clearing components form entity \(entityId) with no components")
			return true
		}
		let removedAll: Bool = allComponents.reduce(true) { $0 && remove(component: $1, from: entityId) }
		return removedAll
	}

}
