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
        for component: Component in components {
            assign(component)
        }
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
        nexus.assign(component: component, to: self)
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

    /// Add an entity as child.
    /// - Parameter entity: The child entity.
    @discardableResult
    @available(*, deprecated, message: "This will be removed in the next minor update.")
    public func addChild(_ entity: Entity) -> Bool {
        nexus.addChild(entity, to: self)
    }

    /// Remove entity as child.
    /// - Parameter entity: The child entity.
    @discardableResult
    @available(*, deprecated, message: "This will be removed in the next minor update.")
    public func removeChild(_ entity: Entity) -> Bool {
        nexus.removeChild(entity, from: self)
    }

    /// Removes all children from this entity.
    @available(*, deprecated, message: "This will be removed in the next minor update.")
    public func removeAllChildren() {
        nexus.removeAllChildren(from: self)
    }

    /// Returns the number of children for this entity.
    @available(*, deprecated, message: "This will be removed in the next minor update.")
    public var numChildren: Int {
        nexus.numChildren(for: self)
    }

    /// Returns an iterator over all components of this entity.
    @inlinable
    public func makeComponentsIterator() -> ComponentsIterator {
        ComponentsIterator(nexus: nexus, entityIdentifier: identifier)
    }

    /// Returns a sequence of all componenents of this entity.
    @inlinable
    public func allComponents() -> AnySequence<Component> {
        AnySequence { self.makeComponentsIterator() }
    }
}

extension Entity {
    public struct ComponentsIterator: IteratorProtocol {
        private var iterator: AnyIterator<Component>

        @usableFromInline
        init(nexus: Nexus, entityIdentifier: EntityIdentifier) {
            if let comps = nexus.get(components: entityIdentifier) {
                iterator = AnyIterator<Component>(comps.compactMap { nexus.get(component: $0, for: entityIdentifier) }.makeIterator())
            } else {
                iterator = AnyIterator { nil }
            }
        }

        public mutating func next() -> Component? {
            iterator.next()
        }
    }
}

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
