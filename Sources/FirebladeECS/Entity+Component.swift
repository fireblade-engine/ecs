//
//  Entity+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.10.17.
//

extension Entity {
    // MARK: Modify in place

    /// Changes a component of this entity in place.
    ///
    /// `body` gets the component stored in the nexus, not a copy: with value type components the change is
    /// visible right away and nothing is written back. A ``ComponentModified`` event is delivered afterwards to
    /// delegates subscribed to ``NexusEventMask/valueChanges``.
    ///
    /// `body` must not add or remove components or entities of the same nexus, and must not read or modify the
    /// component being modified: the nexus stops the process with a message if it does.
    /// If `body` throws, the error is rethrown after the event.
    ///
    /// - Parameters:
    ///   - type: The type of the component to change.
    ///   - body: Changes the component.
    /// - Returns: `false` if this entity has no component of the type or is destroyed (a destroyed entity also
    ///   triggers an assertion failure in debug builds); `body` is not called then.
    /// - Complexity: O(1)
    @inlinable
    @discardableResult
    public func modify<C: Component>(_ type: C.Type, _ body: (inout C) throws -> Void) rethrows -> Bool {
        try nexus.modify(type, for: identifier, body)
    }

    /// Changes a component of this entity in place, adding a default first if the entity has none.
    ///
    /// `makeDefault` is evaluated only when the component is missing. Then ``ComponentAdded`` is delivered, and
    /// ``ComponentModified`` after `body` ran. Nothing is inserted into a destroyed entity: the call does nothing
    /// and triggers an assertion failure in debug builds.
    ///
    /// The restrictions of ``modify(_:_:)`` apply to `body`.
    /// - Parameters:
    ///   - type: The type of the component to change.
    ///   - makeDefault: The component to add if the entity has none.
    ///   - body: Changes the component.
    /// - Complexity: O(1) if the component exists, O(M) otherwise where M is the number of families.
    @inlinable
    public func modify<C: Component>(_ type: C.Type, default makeDefault: @autoclosure () -> C, _ body: (inout C) throws -> Void) rethrows {
        try nexus.modify(type, default: makeDefault(), for: identifier, body)
    }

    // MARK: Read

    /// Retrieves a component of the specified type assigned to this entity.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    public func get<C>() -> C? where C: Component {
        nexus.component(for: identifier)
    }

    /// Retrieves a component of the specified type assigned to this entity.
    /// - Parameter type: The type of the component to retrieve.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @inlinable
    public func get<C>(_ type: C.Type) -> C? where C: Component {
        nexus.component(for: identifier)
    }

    /// Retrieves a component of the specified type assigned to this entity.
    /// - Parameter compType: The type of the component to retrieve. Defaults to the inferred type.
    /// - Returns: The component instance if found; otherwise, `nil`.
    /// - Complexity: O(1)
    @available(*, deprecated, renamed: "get(_:)")
    @inlinable
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        get(compType)
    }

    /// Retrieves components of the specified types assigned to this entity.
    /// - Parameters:
    ///   - components: The component types to retrieve.
    /// - Returns: A tuple containing the optional component instances.
    /// - Complexity: O(1)
    @inlinable
    public func get<each C: Component>(components: repeat (each C).Type) -> (repeat (each C)?) {
        (repeat get((each C).self))
    }

    // MARK: Subscripts

    /// The component of a type: reads a copy, writes in place.
    ///
    /// - Reading returns a copy (`nil` if missing) and never adds anything.
    /// - Mutating through an optional chain, `entity[Position.self]?.x += 1`, changes the stored component in place
    ///   and delivers ``ComponentModified``. Nothing happens if the component is missing.
    /// - Assigning a value sets the component like ``set(_:)-(Component)`` does: adds it or replaces the existing one.
    ///   Assigning `nil` removes it.
    ///
    /// The restrictions of ``modify(_:_:)`` apply to the code that runs while the component is accessed in place.
    /// - Complexity: O(1) for get and in place access, O(M) for adding or removing where M is the number of families.
    @inlinable
    public subscript<Comp>(_ componentType: Comp.Type) -> Comp? where Comp: Component {
        get { self.get(componentType) }
        nonmutating set {
            guard let newComponent = newValue else {
                self.remove(Comp.self)
                return
            }
            self.set(newComponent)
        }
        nonmutating _modify {
            guard let address = nexus.beginModify(Comp.self, for: identifier) else {
                // missing component (or stale handle): changes of the temporary are only kept if it ends up non-nil
                var missing: Comp?
                yield &missing
                if let added = missing {
                    self.set(added)
                }
                return
            }
            // the component moves into the optional while it is accessed and moves back afterwards
            var moved: Comp? = address.move()
            defer {
                if let value = moved {
                    address.initialize(to: value)
                    nexus.endModify(Comp.self, for: identifier)
                } else {
                    nexus.endModifyDiscarding(Comp.self, for: identifier)
                }
            }
            yield &moved
        }
    }

    /// The component of a type, or a default if the entity has none; writes in place.
    ///
    /// Follows `Dictionary.subscript(_:default:)`: reading returns the default without adding anything,
    /// mutating (`entity[Counter.self, default: Counter()].value += 1`) adds the default first if the component is
    /// missing and then changes the stored component in place. `makeDefault` is evaluated only when needed.
    /// Mutating the component of a destroyed entity changes a temporary instead and triggers an assertion failure
    /// in debug builds. Assigning a value sets the component like ``set(_:)-(Component)``.
    ///
    /// The restrictions of ``modify(_:_:)`` apply to the code that runs while the component is accessed in place.
    /// - Complexity: O(1) if the component exists, O(M) when it must be added where M is the number of families.
    @inlinable
    public subscript<Comp>(_ componentType: Comp.Type, default makeDefault: @autoclosure () -> Comp) -> Comp where Comp: Component {
        get { self.get(componentType) ?? makeDefault() }
        nonmutating set { self.set(newValue) }
        nonmutating _modify {
            if !self.has(componentType), nexus.isAlive(identifier) {
                self.set(makeDefault())
            }
            guard let address = nexus.beginModify(Comp.self, for: identifier) else {
                var temporary = makeDefault()
                yield &temporary
                return
            }
            defer { nexus.endModify(Comp.self, for: identifier) }
            yield &address.pointee
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
        self.get(Comp.self)![keyPath: componentKeyPath]
    }

    /// Get the value of a component using the key Path to the property in the component.
    ///
    /// A `Comp` instance must be assigned to this entity!
    /// - Parameter componentKeyPath: The `KeyPath` to the property of the given component.
    /// - Returns: The optional value at the specified key path.
    /// - Complexity: O(1)
    @inlinable
    public func get<Comp, Value>(valueAt componentKeyPath: KeyPath<Comp, Value?>) -> Value? where Comp: Component {
        self.get(Comp.self)![keyPath: componentKeyPath]
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
    ///   The change is made in place in the nexus, also for value type components.
    ///
    /// - Parameters:
    ///   - newValue: The value to set.
    ///   - componentKeyPath: The `WritableKeyPath` to the property of the given component.
    /// - Returns: `true` if the value was set, `false` if this entity is destroyed.
    /// - Complexity: O(1) if component exists, O(M) otherwise where M is the number of families.
    @inlinable
    @discardableResult
    public func set<Comp, Value>(value newValue: Value, for componentKeyPath: WritableKeyPath<Comp, Value>) -> Bool where Comp: Component & DefaultInitializable {
        nexus.modify(Comp.self, default: Comp(), for: identifier) { $0[keyPath: componentKeyPath] = newValue }
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    ///   The change is made in place in the nexus, also for value type components.
    ///
    /// - Parameters:
    ///   - newValue: The value to set.
    ///   - componentKeyPath: The `WritableKeyPath` to the property of the given component.
    /// - Returns: `true` if the value was set, `false` if this entity is destroyed.
    /// - Complexity: O(1) if component exists, O(M) otherwise where M is the number of families.
    @inlinable
    @discardableResult
    public func set<Comp, Value>(value newValue: Value?, for componentKeyPath: WritableKeyPath<Comp, Value?>) -> Bool where Comp: Component & DefaultInitializable {
        nexus.modify(Comp.self, default: Comp(), for: identifier) { $0[keyPath: componentKeyPath] = newValue }
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    ///   The change is made in place in the nexus, also for value type components.
    /// - Complexity: O(1) for get. O(1) for set if component exists, O(M) otherwise.
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: WritableKeyPath<Comp, Value>) -> Value where Comp: Component & DefaultInitializable {
        get { self.get(valueAt: componentKeyPath) }
        nonmutating set { self.set(value: newValue, for: componentKeyPath) }
    }

    /// Set the value of a component using the key path to the property in the component.
    ///
    /// **Behavior:**
    /// - If `Comp` is a component type that is currently *not* assigned to this entity,
    ///   a new instance of `Comp` will be default initialized and `newValue` will be set at the given keyPath.
    ///   The change is made in place in the nexus, also for value type components.
    /// - Complexity: O(1) for get. O(1) for set if component exists, O(M) otherwise.
    @inlinable
    public subscript<Comp, Value>(_ componentKeyPath: WritableKeyPath<Comp, Value?>) -> Value? where Comp: Component & DefaultInitializable {
        get { self.get(valueAt: componentKeyPath) }
        nonmutating set { self.set(value: newValue, for: componentKeyPath) }
    }
}
