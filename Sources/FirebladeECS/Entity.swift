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
    @usableFromInline unowned let nexus: Nexus

    /// The unique entity identifier.
    public private(set) var identifier: EntityIdentifier

    internal init(nexus: Nexus, id: EntityIdentifier) {
        self.nexus = nexus
        self.identifier = id
    }

    /// Returns the number of components for this entity.
    public var numComponents: Int {
        nexus.count(components: identifier)
    }

    @discardableResult
    public func createEntity() -> Entity {
        nexus.createEntity()
    }

    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        createEntity(with: components)
    }

    @discardableResult
    public func createEntity<C>(with components: C) -> Entity where C: Collection, C.Element == Component {
        nexus.createEntity(with: components)
    }

    /// Checks if a component with given type is assigned to this entity.
    /// - Parameter type: the component type.
    public func has<C>(_ type: C.Type) -> Bool where C: Component {
        has(type.identifier)
    }

    /// Checks if a component with a given component identifier is assigned to this entity.
    /// - Parameter compId: the component identifier.
    public func has(_ compId: ComponentIdentifier) -> Bool {
        nexus.has(componentId: compId, entityId: identifier)
    }

    /// Checks if this entity has any components.
    public var hasComponents: Bool {
        nexus.count(components: identifier) > 0
    }

    /// Add one or more components to this entity.
    /// - Parameter components: one or more components.
    @discardableResult
    public func assign(_ components: Component...) -> Entity {
        assign(components)
        return self
    }

    /// Add a component to this entity.
    /// - Parameter component: a component.
    @discardableResult
    public func assign(_ component: Component) -> Entity {
        nexus.assign(component: component, to: self)
        return self
    }

    /// Add a typed component to this entity.
    /// - Parameter component: the typed component.
    @discardableResult
    public func assign<C>(_ component: C) -> Entity where C: Component {
        assign(component)
        return self
    }

    @discardableResult
    public func assign<C>(_ components: C) -> Entity where C: Collection, C.Element == Component {
        nexus.assign(components: components, to: self)
        return self
    }

    /// Remove a component from this entity.
    /// - Parameter component: the component.
    @discardableResult
    public func remove<C>(_ component: C) -> Entity where C: Component {
        remove(component.identifier)
    }

    /// Remove a component by type from this entity.
    /// - Parameter compType: the component type.
    @discardableResult
    public func remove<C>(_ compType: C.Type) -> Entity where C: Component {
        remove(compType.identifier)
    }

    /// Remove a component by id from this entity.
    /// - Parameter compId: the component id.
    @discardableResult
    public func remove(_ compId: ComponentIdentifier) -> Entity {
        nexus.remove(component: compId, from: identifier)
        return self
    }

    /// Remove all components from this entity.
    public func removeAll() {
        nexus.removeAll(components: identifier)
    }

    /// Destroy this entity.
    public func destroy() {
        nexus.destroy(entity: self)
    }

    /// Returns an iterator over all components of this entity.
    @inlinable
    public func makeComponentsIterator() -> ComponentsIterator {
        ComponentsIterator(nexus: nexus, entityIdentifier: identifier)
    }
}

extension Entity {
    public struct ComponentsIterator: IteratorProtocol {
        private var iterator: IndexingIterator<([Component])>?

        @usableFromInline
        init(nexus: Nexus, entityIdentifier: EntityIdentifier) {
            iterator = nexus.get(components: entityIdentifier)?
                .map { nexus.get(unsafe: $0, for: entityIdentifier) }
                .makeIterator()
        }

        public mutating func next() -> Component? {
            iterator?.next()
        }
    }
}
extension Entity.ComponentsIterator: LazySequenceProtocol { }
extension Entity.ComponentsIterator: Sequence { }

extension Entity: Equatable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.nexus === rhs.nexus && lhs.identifier == rhs.identifier
    }
}

extension Entity: CustomStringConvertible {
    public var description: String {
        "<Entity id:\(identifier.id)>"
    }
}

extension Entity: CustomDebugStringConvertible {
    public var debugDescription: String {
        "<Entity id:\(identifier.id) numComponents:\(numComponents)>"
    }
}
