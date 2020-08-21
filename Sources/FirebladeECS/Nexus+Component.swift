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

    public final func assign(component: Component, to entity: Entity) {
        let entityId: EntityIdentifier = entity.identifier
        assign(component: component, entityId: entityId)
        delegate?.nexusEvent(ComponentAdded(component: component.identifier, toEntity: entity.identifier))
    }

    public final func assign<C>(component: C, to entity: Entity) where C: Component {
        assign(component: component, to: entity)
    }

    @inlinable
    public final func get(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let uniformComponents = componentsByType[componentId] else {
            return nil
        }
        return uniformComponents.get(at: entityId.index)
    }

    @inlinable
    public final func get(unsafeComponent componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let uniformComponents = componentsByType[componentId].unsafelyUnwrapped
        return uniformComponents.get(unsafeAt: entityId.index)
    }

    @inlinable
    public final func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
        let componentId: ComponentIdentifier = C.identifier
        return get(componentId: componentId, entityId: entityId)
    }

    @inlinable
    public final func get<C>(unsafeComponentFor entityId: EntityIdentifier) -> C where C: Component {
        let component: Component = get(unsafeComponent: C.identifier, for: entityId)
        // components are guaranteed to be reference types so unsafeDowncast is applicable here
        return unsafeDowncast(component, to: C.self)
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
        return uniformComponents.get(at: entityId.index) as? C
    }
}
