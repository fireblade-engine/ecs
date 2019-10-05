//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    public final var numComponents: Int {
        return componentsByType.reduce(0) { $0 + $1.value.count }
    }

    public final func has(componentId: ComponentIdentifier, entityId: EntityIdentifier) -> Bool {
        guard let uniforms = componentsByType[componentId] else {
            return false
        }
        return uniforms.contains(entityId.id)
    }

    public final func count(components entityId: EntityIdentifier) -> Int {
        return componentIdsByEntity[entityId]?.count ?? 0
    }

    public final func assign(component: Component, to entity: Entity) {
        let componentId: ComponentIdentifier = component.identifier
        let entityId: EntityIdentifier = entity.identifier

        /// test if component is already assigned
        guard !has(componentId: componentId, entityId: entityId) else {
            delegate?.nexusNonFatalError("ComponentAdd collision: \(entityId) already has a component \(component)")
            assertionFailure("ComponentAdd collision: \(entityId) already has a component \(component)")
            return
        }

        // add component instances to uniform component stores
        if componentsByType[componentId] == nil {
            componentsByType[componentId] = UnorderedSparseSet<Component>()
        }
        componentsByType[componentId]?.insert(component, at: entityId.id)

        // assigns the component id to the entity id
        if componentIdsByEntity[entityId] == nil {
            componentIdsByEntity[entityId] = Set<ComponentIdentifier>()
        }
        componentIdsByEntity[entityId]?.insert(componentId) //, at: componentId.hashValue)

        update(familyMembership: entityId)

        delegate?.nexusEvent(ComponentAdded(component: componentId, toEntity: entity.identifier))
    }

    public final func assign<C>(component: C, to entity: Entity) where C: Component {
        assign(component: component, to: entity)
    }

    @inlinable
    public final func get(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let uniformComponents = componentsByType[componentId] else {
            return nil
        }
        return uniformComponents.get(at: entityId.id)
    }

    @inlinable
    public final func get(unsafeComponent componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let uniformComponents = componentsByType[componentId].unsafelyUnwrapped
        return uniformComponents.get(unsafeAt: entityId.id)
    }

    @inlinable
    public final func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
        let componentId: ComponentIdentifier = C.identifier
        return get(componentId: componentId, entityId: entityId)
    }

    @inlinable
    public final func get<C>(unsafeComponentFor entityId: EntityIdentifier) -> C where C: Component {
        let component: Component = get(unsafeComponent: C.identifier, for: entityId)
        /// components are guaranteed to be reference tyes so unsafeDowncast is applicable here
        return unsafeDowncast(component, to: C.self)
    }

    @inlinable
    public final func get(components entityId: EntityIdentifier) -> Set<ComponentIdentifier>? {
        return componentIdsByEntity[entityId]
    }

    @discardableResult
    public final func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
        // delete component instance
        componentsByType[componentId]?.remove(at: entityId.id)
        // unasign component from entity
        componentIdsByEntity[entityId]?.remove(componentId)

        update(familyMembership: entityId)

        delegate?.nexusEvent(ComponentRemoved(component: componentId, from: entityId))
        return true
    }

    @discardableResult
    public final func removeAll(componentes entityId: EntityIdentifier) -> Bool {
        guard let allComponents = get(components: entityId) else {
            delegate?.nexusNonFatalError("clearing components form entity \(entityId) with no components")
            return false
        }
        var iter = allComponents.makeIterator()
        var removedAll: Bool = true
        while let component = iter.next() {
            removedAll = removedAll && remove(component: component, from: entityId)
        }
        return removedAll
    }

    @inlinable
    public final func get<C>(componentId: ComponentIdentifier, entityId: EntityIdentifier) -> C? where C: Component {
        guard let uniformComponents = componentsByType[componentId] else {
            return nil
        }
        return uniformComponents.get(at: entityId.id) as? C
    }
}
