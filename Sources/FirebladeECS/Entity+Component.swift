//
//  Entity+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.10.17.
//

extension Entity {
    /// Retrieves a component of the specified type assigned to this entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    public func get<C>() -> C? where C: Component {
        nexus.get(safe: identifier)
    }

    /// Retrieves a component of the specified type assigned to this entity.
    /// - Parameter compType: The type of the component to retrieve. Defaults to the inferred type.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        nexus.get(safe: identifier)
    }

    /// Retrieves components of the specified types assigned to this entity.
    /// - Parameters:
    ///   - _: The component types to retrieve.
    /// - Returns: A tuple containing the optional component instances.
    /// - Complexity: O(1)
    @inlinable
    public func get<each C: Component>(components _: repeat (each C).Type) -> (repeat (each C)?) {
        (repeat get(component: (each C).self))
    }

    /// Get or set component instance by type via subscript.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   the new instance will be assigned to this entity.
    /// - If `Comp` is already assinged to this entity nothing happens.
    /// - If `Comp` is set to `nil` and an instance of `Comp` is assigned to this entity,
    ///   `Comp` will be removed from this entity.
    /// - Complexity: O(1) for get, O(M) for set where M is the number of families.
    @inlinable
    public subscript<Comp>(_ componentType: Comp.Type) -> Comp? where Comp: Component {
        get { self.get(component: componentType) }
        nonmutating set {
            guard let newComponent = newValue else {
                self.remove(Comp.self)
                return
            }
            if self.get(component: componentType) === newComponent {
                return
            }
            self.assign(newComponent)
        }
    }

    /// Get the value of a component using the key Path to the property in the component.
    ///
    /// A `Comp` instance must be assigned to this entity!
    /// - Parameter componentKeyPath: The `KeyPath` to the property of the given component.
    /// - Returns: The value at the specified key path.
    /// - Complexity: O(1)
    @inlinable
    public func get<Comp, Value>(valueAt componentKeyPath: KeyPath<Comp, Value>) -> Value where Comp: Component {
        self.get(component: Comp.self)![keyPath: componentKeyPath]
    }

    /// Get the value of a component using the key Path to the property in the component.
    ///
    /// A `Comp` instance must be assigned to this entity!
    /// - Parameter componentKeyPath: The `KeyPath` to the property of the given component.
    /// - Returns: The optional value at the specified key path.
    /// - Complexity: O(1)
    @inlinable
    public func get<Comp, Value>(valueAt componentKeyPath: KeyPath<Comp, Value?>) -> Value? where Comp: Component {
        self.get(component: Comp.self)![keyPath: componentKeyPath]
    }

    /// Get the value of a component using the key Path to the property in the component.
    /// - Complexity: O(1)
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: KeyPath<Comp, Value>) -> Value where Comp: Component {
        self.get(valueAt: componentKeyPath)
    }

    /// Get the value of a component using the key Path to the property in the component.
    /// - Complexity: O(1)
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: KeyPath<Comp, Value?>) -> Value? where Comp: Component {
        self.get(valueAt: componentKeyPath)
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    ///
    /// - Parameters:
    ///   - newValue: The value to set.
    ///   - componentKeyPath: The `ReferenceWritableKeyPath` to the property of the given component.
    /// - Returns: Returns true if an action was performed, false otherwise.
    /// - Complexity: O(1) if component exists, O(M) otherwise where M is the number of families.
    @inlinable
    @discardableResult
    public func set<Comp, Value>(value newValue: Value, for componentKeyPath: ReferenceWritableKeyPath<Comp, Value>) -> Bool where Comp: Component & DefaultInitializable {
        guard has(Comp.self) else {
            let newInstance = Comp()
            newInstance[keyPath: componentKeyPath] = newValue
            return nexus.assign(component: newInstance, entityId: identifier)
        }

        get(component: Comp.self)![keyPath: componentKeyPath] = newValue
        return true
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    ///
    /// - Parameters:
    ///   - newValue: The value to set.
    ///   - componentKeyPath: The `ReferenceWritableKeyPath` to the property of the given component.
    /// - Returns: Returns true if an action was performed, false otherwise.
    /// - Complexity: O(1) if component exists, O(M) otherwise where M is the number of families.
    @inlinable
    @discardableResult
    public func set<Comp, Value>(value newValue: Value?, for componentKeyPath: ReferenceWritableKeyPath<Comp, Value?>) -> Bool where Comp: Component & DefaultInitializable {
        guard has(Comp.self) else {
            let newInstance = Comp()
            newInstance[keyPath: componentKeyPath] = newValue
            return nexus.assign(component: newInstance, entityId: identifier)
        }

        get(component: Comp.self)![keyPath: componentKeyPath] = newValue
        return true
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    /// - Complexity: O(1) for get. O(1) for set if component exists, O(M) otherwise.
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: ReferenceWritableKeyPath<Comp, Value>) -> Value where Comp: Component & DefaultInitializable {
        get { self.get(valueAt: componentKeyPath) }
        nonmutating set { self.set(value: newValue, for: componentKeyPath) }
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    /// - Complexity: O(1) for get. O(1) for set if component exists, O(M) otherwise.
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: ReferenceWritableKeyPath<Comp, Value?>) -> Value? where Comp: Component & DefaultInitializable {
        get { self.get(valueAt: componentKeyPath) }
        nonmutating set { self.set(value: newValue, for: componentKeyPath) }
    }
}
