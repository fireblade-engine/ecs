//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

public extension Nexus {
    final var numComponents: Int {
        return componentsByType.reduce(0) { $0 + $1.value.count }
    }

    final func has(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> Bool {
        guard let uniforms: UniformComponents = componentsByType[componentId] else {
            return false
        }
        return uniforms.has(entityIdx)
    }

    final func count(components entityId: EntityIdentifier) -> Int {
        return componentIdsByEntity[entityId.index]?.count ?? 0
    }

    final func assign(component: Component, to entity: Entity) {
        let componentId: ComponentIdentifier = component.identifier
        let entityIdx: EntityIndex = entity.identifier.index
        let entityId: EntityIdentifier = entity.identifier

        /// test if component is already assigned
        guard !has(componentId: componentId, entityIdx: entityIdx) else {
            report("ComponentAdd collision: \(entityIdx) already has a component \(component)")
            assertionFailure("ComponentAdd collision: \(entityIdx) already has a component \(component)")
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
        componentIdsByEntity[entityIdx]?.insert(componentId, at: componentId.hashValue)

        update(familyMembership: entityId)

        notify(ComponentAdded(component: componentId, toEntity: entity.identifier))
    }

    final func assign<C>(component: C, to entity: Entity) where C: Component {
        assign(component: component, to: entity)
    }

    final func get(component componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let uniformComponents: UniformComponents = componentsByType[componentId] else {
            return nil
        }
        return uniformComponents.get(at: entityId.index)
    }

    final func get(unsafeComponent componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let uniformComponents: UniformComponents = componentsByType[componentId].unsafelyUnwrapped
        return uniformComponents.get(unsafeAt: entityId.index)
    }

    final func get<C>(for entityId: EntityIdentifier) -> C? where C: Component {
        let componentId: ComponentIdentifier = C.identifier
        return get(componentId: componentId, entityIdx: entityId.index)
    }

    final func get<C>(unsafeComponentFor entityId: EntityIdentifier) -> C where C: Component {
        let component: Component = get(unsafeComponent: C.identifier, for: entityId)
        /// components are guaranteed to be reference tyes so unsafeDowncast is applicable here
        return unsafeDowncast(component, to: C.self)
    }

    final func get(components entityId: EntityIdentifier) -> SparseComponentIdentifierSet? {
        return componentIdsByEntity[entityId.index]
    }

    @discardableResult
    final func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
        let entityIdx: EntityIndex = entityId.index

        // delete component instance
        componentsByType[componentId]?.remove(at: entityIdx)
        // unasign component from entity
        componentIdsByEntity[entityIdx]?.remove(at: componentId.hashValue)

        update(familyMembership: entityId)

        notify(ComponentRemoved(component: componentId, from: entityId))
        return true
    }

    @discardableResult
    final func clear(componentes entityId: EntityIdentifier) -> Bool {
        guard let allComponents: SparseComponentIdentifierSet = get(components: entityId) else {
            report("clearing components form entity \(entityId) with no components")
            return false
        }
        let removedAll: Bool = allComponents.reduce(true) { $0 && remove(component: $1, from: entityId) }
        return removedAll
    }
}

private extension Nexus {
    final func get<C>(componentId: ComponentIdentifier, entityIdx: EntityIndex) -> C? where C: Component {
        guard let uniformComponents: UniformComponents = componentsByType[componentId] else {
            return nil
        }
        return uniformComponents.get(at: entityIdx) as? C
    }
}
