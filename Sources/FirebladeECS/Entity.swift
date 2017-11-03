//
//  Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public final class Entity: UniqueEntityIdentifiable {

	internal(set) public var identifier: EntityIdentifier = EntityIdentifier.invalid
	public var name: String?

	unowned let nexus: Nexus

	init(nexus: Nexus, id: EntityIdentifier, name: String? = nil) {
		self.nexus = nexus
		self.identifier = id
		self.name = name
	}

}

// MARK: - activatable protocol
extension Entity: Activatable {
	public func activate() {
		//TODO: nexus.activate(entity: self)
	}
	public func deactivate() {
		//TODO: nexus.deactivate(entity: self)
	}
}

// MARK: - Invalidate
extension Entity {

	public var isValid: Bool {
		return nexus.isValid(entity: self)
	}

	internal func invalidate() {
		identifier = EntityIdentifier.invalid
		name = nil
	}
}

// MARK: - Equatable
public func ==(lhs: Entity, rhs: Entity) -> Bool {
	return lhs.identifier == rhs.identifier
}

// MARK: - number of components
public extension Entity {
	public final var numComponents: Int {
		return nexus.count(components: identifier)
	}
}

// MARK: - has component(s)
public extension Entity {

	public final func has<C>(_ type: C.Type) -> Bool where C: Component {
		return has(type.identifier)
	}

	public final func has(_ uct: ComponentIdentifier) -> Bool {
		return nexus.has(componentId: uct, entityIdx: identifier.index)
	}

	public final var hasComponents: Bool {
		return nexus.count(components: identifier) > 0
	}

}

// MARK: - add component(s)
public extension Entity {

	@discardableResult
	public final func assign(_ components: Component...) -> Entity {
		for component: Component in components {
			assign(component)
		}
		return self
	}

	@discardableResult
	public final func assign(_ component: Component) -> Entity {
		nexus.assign(component: component, to: self)
		return self
	}

	@discardableResult
	public final func assign<C>(_ component: C) -> Entity where C: Component {
		nexus.assign(component: component, to: self)
		return self
	}

	@discardableResult
	public static func += <C>(lhs: Entity, rhs: C) -> Entity where C: Component {
		return lhs.assign(rhs)
	}

	@discardableResult
	public static func << <C>(lhs: Entity, rhs: C) -> Entity where C: Component {
		return lhs.assign(rhs)
	}
}

// MARK: - remove component(s)
public extension Entity {

	@discardableResult
	public final func remove<C>(_ component: C) -> Entity where C: Component {
		return remove(component.identifier)
	}

	@discardableResult
	public final func remove<C>(_ componentType: C.Type) -> Entity where C: Component {
		return remove(componentType.identifier)
	}

	@discardableResult
	public final func remove(_ uct: ComponentIdentifier) -> Entity {
		nexus.remove(component: uct, from: identifier)
		return self
	}

	public final func clear() {
		nexus.clear(componentes: identifier)
	}

	@discardableResult
	public static func -= <C>(lhs: Entity, rhs: C) -> Entity where C: Component {
		return lhs.remove(rhs)
	}

	@discardableResult
	public static func -= <C>(lhs: Entity, rhs: C.Type) -> Entity where C: Component {
		return lhs.remove(rhs)
	}
}

// MARK: - destroy/deinit entity
extension Entity {
	public final func destroy() {
		nexus.destroy(entity: self)
	}
}
