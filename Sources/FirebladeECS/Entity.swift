//
//  Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public final class Entity: UniqueEntityIdentifiable {

	internal(set) public var identifier: EntityIdentifier = EntityIdentifier.invalid
	public var name: String?

	fileprivate let nexus: Nexus

	init(nexus: Nexus, id: EntityIdentifier, name: String? = nil) {
		self.nexus = nexus
		self.identifier = id
		self.name = name
	}

}

// MARK: - Invalidate
extension Entity {

	public var isValid: Bool {
		return nexus.isValid(entity: self)
	}

	func invalidate() {
		assert(nexus.isValid(entity: identifier), "Invalid entity \(self) is being invalidated.")
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
		return nexus.has(component: uct, entity: identifier)
	}

	public final var hasComponents: Bool {
		return nexus.count(components: identifier) > 0
	}

}

// MARK: - add component(s)
public extension Entity {

	@discardableResult
	public final func assign<C>(_ component: C) -> Entity where C: Component {
		nexus.assign(component: component, to: identifier)
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

// MARK: - get components
public extension Entity {

	public final func get<C>() -> C? where C: Component {
		return nexus.get(component: C.identifier, for: identifier)
	}

	public final func get<C>(_ componentType: C.Type) -> C? where C: Component {
		return get()
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
	final func destroy() {
		nexus.destroy(entity: self)
	}
}

// MARK: - component tuple access
public extension Entity {

	public func component<A>(_: A.Type) -> A where A: Component {
		guard let a: A = nexus.get(component: A.identifier, for: identifier) else {
			fatalError("Component Mapping Error: '\(A.self)' component was not found in entity '\(self)'")
		}
		return a
	}

	public func components<A, B>(_: A.Type, _: B.Type) -> (A, B) where A: Component, B: Component {
		let a: A = component(A.self)
		let b: B = component(B.self)
		return (a, b)
	}
	public func components<A, B, C>(_: A.Type, _: B.Type, _: C.Type) -> (A, B, C) where A: Component, B: Component, C: Component {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		return (a, b, c)
	}
	public func components<A, B, C, D>(_: A.Type, _: B.Type, _: C.Type, _: D.Type) -> (A, B, C, D) where A: Component, B: Component, C: Component, D: Component {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		return (a, b, c, d)
	}
	public func components<A, B, C, D, E>(_: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type) -> (A, B, C, D, E) where A: Component, B: Component, C: Component, D: Component, E: Component {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		let e: E = component(E.self)
		return (a, b, c, d, e)
	}
	public func components<A, B, C, D, E, F>(_: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _: F.Type) -> (A, B, C, D, E, F) where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		let e: E = component(E.self)
		let f: F = component(F.self)
		return (a, b, c, d, e, f)
	}
}

/*

extension Entity: EventDispatcher {
	public func dispatch<E>(_ event: E) where E: Event {
		eventDispatcher.dispatch(event)
	}

	fileprivate func unowned(_ closure: @escaping (Entity) -> Void) {
		#if DEBUG
			let preActionCount: Int = retainCount(self)
		#endif
		let unownedClosure = { [unowned self] in
			closure(self)
		}
		unownedClosure()
		#if DEBUG
			let postActionCount: Int = retainCount(self)
			assert(postActionCount == preActionCount, "retain count missmatch [\(preActionCount)] -> [\(postActionCount)]")
		#endif
	}

	private func notifyInit() {
		unowned {
			$0.dispatch(EntityCreated(entity: $0))
		}
	}

	private func notify<C>(add component: C) {
		unowned {
			$0.dispatch(ComponentAdded(to: $0))
		}
	}

	private func notify<C>(update newComponent: C, previous previousComponent: C) {
		unowned {
			$0.dispatch(ComponentUpdated(at: $0))
		}
	}

	private func notify<C>(removed component: C) {
		unowned {
			$0.dispatch(ComponentRemoved(from: $0))
		}
	}

	private func notify(removed component) {
		//unowned { /* this keeps a reference since we need it */
		dispatch(ComponentRemoved(from: self))
		//}
	}

	private func notifyDestoryed() {
		//unowned {
		//$0.dispatch(event: EntityDestroyed(entity: $0))
		//TODO: here entity is already dead
		//}
	}

}

// MARK: - debugging and string representation

extension Entity: CustomStringConvertible {

	fileprivate var componentsString: String {
		let compTypes: [String] = componentMap.map { String(describing: $0.value.uct.type) }
		return compTypes.joined(separator: ",")
	}

	public var description: String {
		return "Entity[\(uei)][\(numComponents):\(componentsString)]"
	}

}

extension Entity: CustomPlaygroundQuickLookable {
	public var customPlaygroundQuickLook: PlaygroundQuickLook {
		return .text(self.description)
	}
}
*/
