//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// The total number of components managed by the Nexus.
    public final var numComponents: Int {
        componentsByType.reduce(0) { $0 + $1.value.count }
    }

    /// Checks if a component with a given identifier is assigned to an entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the component is assigned to the entity; otherwise, `false`.
    public final func has(componentId: ComponentIdentifier, entityId: EntityIdentifier) -> Bool {
        guard let uniforms = componentsByType[componentId] else {
            return false
        }
        return uniforms.contains(entityId.index)
    }

    /// Returns the number of components assigned to a specific entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The count of assigned components.
    public final func count(components entityId: EntityIdentifier) -> Int {
        componentIdsByEntity[entityId]?.count ?? 0
    }

    /// Assigns a component to an entity.
    /// - Parameters:
    ///   - component: The component to assign.
    ///   - entity: The entity to assign the component to.
    /// - Returns: `true` if the assignment was successful.
    @discardableResult
    public final func assign(component: Component, to entity: Entity) -> Bool {
        let entityId: EntityIdentifier = entity.identifier
        return assign(component: component, entityId: entityId)
    }

    /// Assigns a collection of components to an entity.
    /// - Parameters:
    ///   - components: The collection of components to assign.
    ///   - entity: The entity to assign the components to.
    /// - Returns: `true` if all assignments were successful.
    @discardableResult
    public final func assign(components: some Collection<Component>, to entity: Entity) -> Bool {
        assign(components: components, to: entity.identifier)
    }

    /// Safely retrieves a component by its identifier for a given entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    @inlinable
    public final func get(safe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let uniformComponents = componentsByType[componentId], uniformComponents.contains(entityId.index) else {
            return nil
        }
        return uniformComponents.get(at: entityId.index)
    }

    /// Unsafely retrieves a component by its identifier for a given entity.
    ///
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: The component instance.
    /// - Precondition: The component MUST be assigned to the entity.
    @inlinable
    public final func get(unsafe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let uniformComponents = componentsByType[componentId].unsafelyUnwrapped
        return uniformComponents.get(unsafeAt: entityId.index)
    }

    /// Safely retrieves a typed component for a given entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: The cast component instance if found; otherwise, `nil`.
    @inlinable
    public final func get<C: Component>(safe componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> C? {
        get(safe: componentId, for: entityId) as? C
    }

    /// Safely retrieves a typed component for a given entity using the component type's identifier.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    @inlinable
    public final func get<C: Component>(safe entityId: EntityIdentifier) -> C? {
        get(safe: C.identifier, for: entityId)
    }

    /// Unsafely retrieves a typed component for a given entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The component instance.
    /// - Precondition: The component MUST be assigned to the entity.
    @inlinable
    public final func get<C: Component>(unsafe entityId: EntityIdentifier) -> C {
        let component: Component = get(unsafe: C.identifier, for: entityId)
        // components are guaranteed to be reference types so unsafeDowncast is applicable here
        return unsafeDowncast(component, to: C.self)
    }

    /// Retrieves all component identifiers assigned to a specific entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: A set of component identifiers, or `nil` if the entity has no components.
    @inlinable
    public final func get(components entityId: EntityIdentifier) -> Set<ComponentIdentifier>? {
        componentIdsByEntity[entityId]
    }

    /// Removes a component from an entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component to remove.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the component was removed; otherwise, `false`.
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

    /// Removes all components from an entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: `true` if all components were successfully removed.
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
