//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    public final var numComponents: Int {
        componentsByType.reduce(0) { $0 + $1.value.count }
    }

    public final func has(componentId: ComponentIdentifier, entityId: EntityIdentifier) -> Bool {
        guard let uniforms = componentsByType[componentId] else {
            return false
        }
        return uniforms.contains(entityId.index)
    }

    public final func count(components entityId: EntityIdentifier) -> Int {
        componentIdsByEntity[entityId]?.count ?? 0
    }

    @discardableResult
    public final func assign(component: Component, to entity: Entity) -> Bool {
        let entityId: EntityIdentifier = entity.identifier
        return assign(component: component, entityId: entityId)
    }

    @discardableResult
    public final func assign(component: some Component, to entity: Entity) -> Bool {
        assign(component: component, to: entity)
    }

    @discardableResult
    public final func assign(components: some Collection<Component>, to entity: Entity) -> Bool {
        assign(components: components, to: entity.identifier)
    }

    @inlinable
    public final func get(safe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let uniformComponents = componentsByType[componentId], uniformComponents.contains(entityId.index) else {
            return nil
        }
        return uniformComponents.get(at: entityId.index)
    }

    @inlinable
    public final func get(unsafe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let uniformComponents = componentsByType[componentId].unsafelyUnwrapped
        return uniformComponents.get(unsafeAt: entityId.index)
    }

    @inlinable
    public final func get<C>(safe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> C? where C: Component {
        get(safe: componentId, for: entityId) as? C
    }

    @inlinable
    public final func get<C>(safe entityId: EntityIdentifier) -> C? where C: Component {
        get(safe: C.identifier, for: entityId)
    }

    @inlinable
    public final func get<C>(unsafe entityId: EntityIdentifier) -> C where C: Component {
        let component: Component = get(unsafe: C.identifier, for: entityId)
        // components are guaranteed to be reference types so unsafeDowncast is applicable here
        return component as! C
    }

    @inlinable
    public final func get(components entityId: EntityIdentifier) -> Set<ComponentIdentifier>? {
        componentIdsByEntity[entityId]
    }

    @discardableResult
    public final func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
        // delete component instance
        componentsByType[componentId]?.remove(at: entityId.index)
        // un-assign component from entity
        componentIdsByEntity[entityId]?.remove(componentId)

        update(familyMembership: entityId)

        delegate?.nexusEvent(ComponentRemoved(component: componentId, from: entityId))
        return true
    }

    @discardableResult
    public final func removeAll(components entityId: EntityIdentifier) -> Bool {
        guard let allComponents = get(components: entityId) else {
            delegate?.nexusNonFatalError("clearing components form entity \(entityId) with no components")
            return false
        }
        var iter = allComponents.makeIterator()
        var removedAll = true
        while let component = iter.next() {
            removedAll = removedAll && remove(component: component, from: entityId)
        }
        return removedAll
    }
}
