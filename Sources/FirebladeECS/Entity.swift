//
//	Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Entity**
///
///  An entity is a general purpose object.
///  It only consists of a unique id (EntityIdentifier).
///  Components can be assigned to an entity to give it behavior or functionality.
///  An entity creates the relationship between all it's assigned components.
///
/// - Important: An entity does not keep its ``Nexus`` alive. Using an entity after its nexus is deallocated is
///   undefined behavior.
public struct Entity {
    /// The Nexus managing this entity.
    ///
    /// An unchecked, non-owning reference: copying an entity costs no reference counting. An entity handle
    /// must not be used after its nexus is deallocated; keep the nexus alive for as long as you use its entities.
    /// (The same trade-off as flecs, whose `flecs::entity` holds a raw `world_t*`.)
    @usableFromInline unowned(unsafe) let nexus: Nexus

    /// The unique entity identifier.
    public private(set) var identifier: EntityIdentifier

    /// Initializes a new entity instance.
    ///
    /// Entities are value types that act as a handle to the data stored in the `Nexus`.
    /// - Parameters:
    ///   - nexus: The nexus managing this entity's components.
    ///   - id: The unique identifier for this entity.
    /// - Complexity: O(1)
    init(nexus: Nexus, id: EntityIdentifier) {
        self.nexus = nexus
        identifier = id
    }

    /// Returns the number of components for this entity.
    /// - Complexity: O(1)
    public var numComponents: Int {
        nexus.count(components: identifier)
    }

    /// Creates a new entity.
    /// - Returns: The created entity.
    /// - Complexity: O(1)
    @discardableResult
    public func createEntity() -> Entity {
        nexus.createEntity()
    }

    /// Creates a new entity with the provided components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The created entity.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func createEntity<each C: Component>(with components: repeat each C) -> Entity {
        nexus.createEntity(with: repeat each components)
    }

    /// Creates a new entity with the provided components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The created entity.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func createEntity(with components: some Collection<Component>) -> Entity {
        nexus.createEntity(with: components)
    }

    /// Checks if a component with given type is assigned to this entity.
    /// - Parameter type: the component type.
    /// - Complexity: O(1)
    public func has(_ type: (some Component).Type) -> Bool {
        nexus.has(componentIndex: type.componentIndex, entityId: identifier)
    }

    /// Checks if a component with a given component identifier is assigned to this entity.
    /// - Parameter compId: the component identifier.
    /// - Complexity: O(1)
    public func has(_ compId: ComponentIdentifier) -> Bool {
        nexus.has(componentId: compId, entityId: identifier)
    }

    /// Checks if this entity has any components.
    /// - Complexity: O(1)
    public var hasComponents: Bool {
        nexus.count(components: identifier) > 0
    }

    /// Sets one or more components of this entity: adds new ones and replaces existing ones.
    ///
    /// If the entity already has a component of the same type, that component is replaced and a
    /// ``ComponentReplaced`` event is delivered to delegates subscribed to ``NexusEventMask/valueChanges``.
    /// Adding a new component delivers ``ComponentAdded``. Setting a component of a destroyed entity does nothing.
    /// - Parameter components: one or more components.
    /// - Returns: This entity (for chaining).
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    @discardableResult
    public func set<each C: Component>(_ components: repeat each C) -> Entity {
        _ = nexus.assign(components: repeat each components, entityId: identifier)
        return self
    }

    /// Sets a component of this entity: adds it, or replaces the one of the same type.
    ///
    /// If the entity already has a component of the same type, that component is replaced and a
    /// ``ComponentReplaced`` event is delivered to delegates subscribed to ``NexusEventMask/valueChanges``.
    /// Adding a new component delivers ``ComponentAdded``. Setting a component of a destroyed entity does nothing.
    /// - Parameter component: a component.
    /// - Returns: This entity (for chaining).
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func set(_ component: Component) -> Entity {
        _ = nexus.assign(component: component, entityId: identifier)
        return self
    }

    /// Sets a collection of components of this entity: adds new ones and replaces existing ones.
    ///
    /// If the entity already has a component of the same type, that component is replaced and a
    /// ``ComponentReplaced`` event is delivered to delegates subscribed to ``NexusEventMask/valueChanges``.
    /// Adding a new component delivers ``ComponentAdded``. Setting a component of a destroyed entity does nothing.
    /// - Parameter components: The components to set.
    /// - Returns: This entity (for chaining).
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func set(_ components: some Collection<Component>) -> Entity {
        _ = nexus.assign(components: components, to: identifier)
        return self
    }

    /// Add one or more components to this entity.
    /// - Parameter components: one or more components.
    /// - Complexity: O(M) where M is the number of families.
    @available(*, deprecated, renamed: "set(_:)")
    @discardableResult
    public func assign<each C: Component>(_ components: repeat each C) -> Entity {
        set(repeat each components)
    }

    /// Add a single component to this entity.
    /// - Parameter component: a component.
    /// - Complexity: O(M) where M is the number of families.
    @available(*, deprecated, renamed: "set(_:)")
    @discardableResult
    public func assign(_ component: Component) -> Entity {
        set(component)
    }

    /// Assigns a collection of components to this entity.
    /// - Parameter components: The components to assign.
    /// - Returns: This entity (for chaining).
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @available(*, deprecated, renamed: "set(_:)")
    @discardableResult
    public func assign(_ components: some Collection<Component>) -> Entity {
        set(components)
    }

    /// Removes the component of the same type as `component` from this entity.
    /// - Parameter component: A component; only its type is used.
    /// - Returns: `true` if the entity had such a component and it was removed, `false` if it was not there or the
    ///   entity is destroyed (an assertion failure in debug builds).
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ component: some Component) -> Bool {
        remove(component.identifier)
    }

    /// Removes a component by type from this entity.
    /// - Parameter compType: The component type.
    /// - Returns: `true` if the entity had such a component and it was removed, `false` if it was not there or the
    ///   entity is destroyed (an assertion failure in debug builds).
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ compType: (some Component).Type) -> Bool {
        remove(compType.identifier)
    }

    /// Removes a component by id from this entity.
    /// - Parameter compId: The component id.
    /// - Returns: `true` if the entity had such a component and it was removed, `false` if it was not there or the
    ///   entity is destroyed (an assertion failure in debug builds).
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ compId: ComponentIdentifier) -> Bool {
        guard nexus.isAlive(identifier) else {
            nexus.reportStaleHandle(identifier)
            return false
        }
        guard has(compId) else {
            return false
        }
        return nexus.remove(component: compId, from: identifier)
    }

    /// Remove all components from this entity.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    public func removeAll() {
        nexus.removeAll(components: identifier)
    }

    /// Destroy this entity.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    public func destroy() {
        nexus.destroy(entity: self)
    }

    /// Returns an iterator over all components of this entity.
    /// - Complexity: O(1)
    @inlinable
    public func makeComponentsIterator() -> ComponentsIterator {
        ComponentsIterator(nexus: nexus, entityIdentifier: identifier)
    }
}

extension Entity {
    /// An iterator over the components of an entity.
    public struct ComponentsIterator: IteratorProtocol {
        private var iterator: IndexingIterator<[Component]>?

        /// Creates a new iterator for the given entity.
        /// - Parameters:
        ///   - nexus: The nexus instance.
        ///   - entityIdentifier: The entity identifier.
        /// - Complexity: O(C) where C is the number of components.
        @usableFromInline
        init(nexus: Nexus, entityIdentifier: EntityIdentifier) {
            guard nexus.isAlive(entityIdentifier) else {
                return
            }
            iterator = nexus.backend.componentIndices(of: entityIdentifier)
                .compactMap { nexus.backend.anyComponent(componentIndex: $0, for: entityIdentifier) }
                .makeIterator()
        }

        /// Advances to the next component and returns it, or `nil` if no next element exists.
        /// - Returns: The next component in the sequence, or `nil`.
        /// - Complexity: O(1)
        public mutating func next() -> Component? {
            iterator?.next()
        }
    }
}

extension Entity.ComponentsIterator: LazySequenceProtocol {}
extension Entity.ComponentsIterator: Sequence {}

extension Entity: Equatable {
    /// Returns a Boolean value indicating whether two entities are equal.
    ///
    /// Entities are considered equal if they belong to the same Nexus and have the same identifier.
    /// - Parameters:
    ///   - lhs: An entity to compare.
    ///   - rhs: Another entity to compare.
    /// - Complexity: O(1)
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.nexus === rhs.nexus && lhs.identifier == rhs.identifier
    }
}

extension Entity: CustomStringConvertible {
    /// A textual representation of the entity.
    /// - Complexity: O(1)
    public var description: String {
        "<Entity id:\(identifier)>"
    }
}

extension Entity: CustomDebugStringConvertible {
    /// A textual representation of the entity, suitable for debugging.
    public var debugDescription: String {
        "<Entity id:\(identifier) numComponents:\(numComponents)>"
    }
}

extension Entity: Sendable {}
