//
//  Nexus+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// The total number of component instances managed by the Nexus.
    /// - Complexity: O(T) where T is the number of component types.
    public final var numComponents: Int {
        backend.totalComponentCount
    }

    /// Checks if a component with a given identifier is assigned to an entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the component is assigned to the entity; otherwise, `false`.
    /// - Complexity: O(1)
    public final func has(componentId: ComponentIdentifier, entityId: EntityIdentifier) -> Bool {
        guard let componentIndex = backend.componentIndex(of: componentId) else {
            return false
        }
        return backend.has(componentIndex: componentIndex, for: entityId)
    }

    /// Checks if a component with a given index is assigned to an entity.
    /// - Parameters:
    ///   - componentIndex: The ``Component/componentIndex`` of the component type.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the component is assigned to the entity; otherwise, `false`.
    /// - Complexity: O(1)
    @inlinable
    final func has(componentIndex: Int, entityId: EntityIdentifier) -> Bool {
        backend.has(componentIndex: componentIndex, for: entityId)
    }

    /// Returns the number of components assigned to a specific entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The count of assigned components.
    /// - Complexity: O(1)
    public final func count(components entityId: EntityIdentifier) -> Int {
        backend.componentCount(of: entityId)
    }

    /// Assigns a component to an entity.
    /// - Parameters:
    ///   - component: The component to assign.
    ///   - entity: The entity to assign the component to.
    /// - Returns: `true` if the assignment was successful.
    /// - Complexity: O(M) where M is the number of families.
    @available(*, deprecated, message: "Use entity.set(_:) instead. Get the entity for an identifier with nexus.entity(_:).")
    @discardableResult
    public final func assign(component: Component, to entity: Entity) -> Bool {
        let entityId: EntityIdentifier = entity.identifier
        return assign(component: component, entityId: entityId)
    }

    /// Assigns multiple components to an entity.
    /// - Parameters:
    ///   - components: The components to assign.
    ///   - entity: The entity to assign the components to.
    /// - Returns: `true` if all assignments were successful.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    @available(*, deprecated, message: "Use entity.set(_:) instead. Get the entity for an identifier with nexus.entity(_:).")
    @discardableResult
    public final func assign<each C: Component>(components: repeat each C, to entity: Entity) -> Bool {
        assign(components: repeat each components, entityId: entity.identifier)
    }

    /// Assigns a collection of components to an entity.
    /// - Parameters:
    ///   - components: The collection of components to assign.
    ///   - entity: The entity to assign the components to.
    /// - Returns: `true` if all assignments were successful.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @available(*, deprecated, message: "Use entity.set(_:) instead. Get the entity for an identifier with nexus.entity(_:).")
    @discardableResult
    public final func assign(components: some Collection<Component>, to entity: Entity) -> Bool {
        assign(components: components, to: entity.identifier)
    }

    /// Retrieves a component by its identifier for a given entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    final func component(_ componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component? {
        guard let componentIndex = backend.componentIndex(of: componentId) else {
            return nil
        }
        return backend.anyComponent(componentIndex: componentIndex, for: entityId)
    }

    /// Retrieves a typed component for a given entity using the component type's identifier.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    final func component<C: Component>(for entityId: EntityIdentifier) -> C? {
        backend.get(C.self, for: entityId)
    }

    /// Retrieves a component by its identifier for a given entity, without checking that it exists.
    /// - Parameters:
    ///   - componentId: The identifier of the component.
    ///   - entityId: The identifier of the entity.
    /// - Returns: The component instance.
    /// - Precondition: The component MUST be assigned to the entity.
    /// - Complexity: O(1)
    @inlinable
    final func unsafeComponent(_ componentId: ComponentIdentifier, for entityId: EntityIdentifier) -> Component {
        let componentIndex = backend.componentIndex(of: componentId).unsafelyUnwrapped
        return backend.anyComponent(componentIndex: componentIndex, for: entityId).unsafelyUnwrapped
    }

    /// Retrieves a typed component for a given entity, without checking that it exists.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: The component instance.
    /// - Precondition: The component MUST be assigned to the entity.
    /// - Complexity: O(1)
    @inlinable
    final func unsafeComponent<C: Component>(for entityId: EntityIdentifier) -> C {
        backend.unsafeGet(C.self, for: entityId)
    }

    /// Retrieves all component identifiers assigned to a specific entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: A set of component identifiers, or `nil` if the entity has no components.
    /// - Complexity: O(1)
    @inlinable
    public final func get(components entityId: EntityIdentifier) -> Set<ComponentIdentifier>? {
        guard backend.isAlive(entityId) else {
            return nil
        }
        return Set(backend.componentIndices(of: entityId).compactMap { backend.identifier(ofComponentIndex: $0) })
    }

    /// Removes a component from an entity.
    /// - Parameters:
    ///   - componentId: The identifier of the component to remove.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the component was removed; `false` if the entity identifier is stale or unknown.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public final func remove(component componentId: ComponentIdentifier, from entityId: EntityIdentifier) -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        // delete component instance and un-assign it from the entity
        if let componentIndex = backend.componentIndex(of: componentId) {
            backend.remove(componentIndex: componentIndex, from: entityId)
        }

        update(familyMembership: entityId)

        delegate?.nexusEvent(ComponentRemoved(component: componentId, from: entityId))
        return true
    }

    /// Removes all components from an entity.
    /// - Parameter entityId: The identifier of the entity.
    /// - Returns: `true` if all components were successfully removed.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    @discardableResult
    public final func removeAll(components entityId: EntityIdentifier) -> Bool {
        guard backend.isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        var removedAll = true
        for componentIndex in backend.componentIndices(of: entityId) {
            guard let componentId = backend.identifier(ofComponentIndex: componentIndex) else {
                continue
            }
            removedAll = remove(component: componentId, from: entityId) && removedAll
        }
        return removedAll
    }
}
