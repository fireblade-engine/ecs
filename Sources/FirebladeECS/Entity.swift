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
public struct Entity {
    /// The Nexus managing this entity.
    @usableFromInline unowned let nexus: Nexus

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
    public func createEntity(with components: Component...) -> Entity {
        createEntity(with: components)
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
        has(type.identifier)
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

    /// Add one or more components to this entity.
    /// - Parameter components: one or more components.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func assign(_ components: Component...) -> Entity {
        assign(components)
        return self
    }

    /// Add a component to this entity.
    /// - Parameter component: a component.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func assign(_ component: Component) -> Entity {
        nexus.assign(component: component, to: self)
        return self
    }

    /// Assigns a collection of components to this entity.
    /// - Parameter components: The components to assign.
    /// - Returns: This entity (for chaining).
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func assign(_ components: some Collection<Component>) -> Entity {
        nexus.assign(components: components, to: self)
        return self
    }

    /// Remove a component from this entity.
    /// - Parameter component: the component.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ component: some Component) -> Entity {
        remove(component.identifier)
    }

    /// Remove a component by type from this entity.
    /// - Parameter compType: the component type.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ compType: (some Component).Type) -> Entity {
        remove(compType.identifier)
    }

    /// Remove a component by id from this entity.
    /// - Parameter compId: the component id.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func remove(_ compId: ComponentIdentifier) -> Entity {
        nexus.remove(component: compId, from: identifier)
        return self
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
            iterator = nexus.get(components: entityIdentifier)?
                .map { nexus.get(unsafe: $0, for: entityIdentifier) }
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
        "<Entity id:\(identifier.id)>"
    }
}

extension Entity: CustomDebugStringConvertible {
    /// A textual representation of the entity, suitable for debugging.
    public var debugDescription: String {
        "<Entity id:\(identifier.id) numComponents:\(numComponents)>"
    }
}

extension Entity: Sendable {}
