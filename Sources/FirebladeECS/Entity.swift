//
//	Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct Entity: UniqueEntityIdentifiable {
    @usableFromInline unowned let nexus: Nexus // FIXME: weak/unowned reference?

    public private(set) var identifier: EntityIdentifier = .invalid

    internal init(nexus: Nexus, id: EntityIdentifier) {
		self.nexus = nexus
		self.identifier = id
	}
}

// MARK: - Equatable
extension Entity: Equatable { }

// MARK: - number of components
public extension Entity {
	var numComponents: Int {
		return nexus.count(components: identifier)
	}
}

// MARK: - has component(s)
public extension Entity {
	func has<C>(_ type: C.Type) -> Bool where C: Component {
		return has(type.identifier)
	}

	func has(_ compId: ComponentIdentifier) -> Bool {
		return nexus.has(componentId: compId, entityIdx: identifier.index)
	}

	var hasComponents: Bool {
		return nexus.count(components: identifier) > 0
	}
}

// MARK: - add component(s)
public extension Entity {
	@discardableResult
	func assign(_ components: Component...) -> Entity {
		for component: Component in components {
			assign(component)
		}
		return self
	}

	@discardableResult
	func assign(_ component: Component) -> Entity {
		nexus.assign(component: component, to: self)
		return self
	}

	@discardableResult
	func assign<C>(_ component: C) -> Entity where C: Component {
		nexus.assign(component: component, to: self)
		return self
	}
}

// MARK: - remove component(s)
public extension Entity {
	@discardableResult
	func remove<C>(_ component: C) -> Entity where C: Component {
		return remove(component.identifier)
	}

	@discardableResult
	func remove<C>(_ compType: C.Type) -> Entity where C: Component {
		return remove(compType.identifier)
	}

	@discardableResult
	func remove(_ compId: ComponentIdentifier) -> Entity {
		nexus.remove(component: compId, from: identifier)
		return self
	}

	func clear() {
		nexus.clear(componentes: identifier)
	}
}

// MARK: - destroy/deinit entity
public extension Entity {
	func destroy() {
		nexus.destroy(entity: self)
	}
}
