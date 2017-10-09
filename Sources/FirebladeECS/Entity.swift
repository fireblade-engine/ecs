//
//  Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public final class Entity: UniqueEntityIdentifiable {
	public let uei: UEI

	fileprivate var eventDispatcher: EventDispatcher

	public private(set) var componentMap: [UCT:Component]

	init(uei: UEI, dispatcher: EventDispatcher) {
		self.uei = uei
		self.eventDispatcher = dispatcher
		componentMap = [UCT: Component]()
		componentMap.reserveCapacity(2)
		defer {
			notifyInit()
		}
	}

	deinit {
		defer {
			destroy()
		}
	}
}

// MARK: - Equatable
public func ==(lhs: Entity, rhs: Entity) -> Bool {
	return lhs.uei == rhs.uei
}

// MARK: - number of components
public extension Entity {
	public final var numComponents: Int { return componentMap.count }
}

// MARK: - has component(s)
public extension Entity {

	public final func has(_ component: Component.Type) -> Bool {
		return has(UCT(component))
	}

	public final func has(_ component: UCT) -> Bool {
		return componentMap[component] != nil
	}

	public final var hasComponents: Bool { return !componentMap.isEmpty }

}

// MARK: - add/push component(s)
public extension Entity {

	@discardableResult
	public final func push<C: Component>(component: C) -> Entity {
		let previousComponent: C? = componentMap.updateValue(component, forKey: component.uct) as? C
		if let pComp: C = previousComponent {
			notify(update: component, previous: pComp)
		} else {
			notify(add: component)
		}
		return self
	}

	@discardableResult
	public final func add<C: Component>(component: C) -> Entity {
		return push(component: component)
	}

	@discardableResult
	public static func += <C: Component>(lhs: Entity, rhs: C) -> Entity {
		return lhs.push(component: rhs)
	}

	@discardableResult
	public static func << <C: Component>(lhs: Entity, rhs: C) -> Entity {
		return lhs.push(component: rhs)
	}
}

// MARK: - peek component
public extension Entity {

	public final func peekComponent<C: Component>() -> C? {
		return componentMap[C.uct] as? C
	}

	public final func peek<C: Component>(_ componentType: C.Type) -> C? {
		return componentMap[componentType.uct] as? C
	}

	public final func peek<C: Component>(_ uct: UCT) -> C? {
		return componentMap[uct] as? C
	}

	public final func peek<C: Component>(_ unwrapping: (C?) -> C) -> C {
		return unwrapping(peekComponent())
	}

	@discardableResult
	public final func peek<C: Component, Result>(_ applying: (C?) -> Result) -> Result {
		return applying(peekComponent())
	}

}
// MARK: - remove component(s)
public extension Entity {

	@discardableResult
	public final func remove(_ component: Component) -> Entity {
		return remove(component.uct)
	}

	@discardableResult
	public final func remove<C: Component>(_ componentType: C.Type) -> Entity {
		let removedComponent: C? = componentMap.removeValue(forKey: C.uct) as? C
		if let rComp: C = removedComponent {
			notify(removed: rComp)
		}
		return self
	}

	@discardableResult
	public final func remove(_ uct: UCT) -> Entity {
		let removedComponent = componentMap.removeValue(forKey: uct)
		if let rComp = removedComponent {
			assert(rComp.uct.type == uct.type)
			notify(removed: rComp)
		}
		return self
	}

	public final func removeAll() {
		componentMap.forEach { remove($0.key) }
	}

	@discardableResult
	public static func -= <C: Component>(lhs: Entity, rhs: C) -> Entity {
		return lhs.remove(rhs)
	}

	@discardableResult
	public static func -= <C: Component>(lhs: Entity, rhs: C.Type) -> Entity {
		return lhs.remove(rhs)
	}
}

// MARK: - destroy/deinit entity
extension Entity {
	final func destroy() {
		removeAll()
		UEI.free(uei)
		notifyDestoryed()
	}
}

extension Entity: EventDispatcher {
	public func dispatch<E>(_ event: E) where E : Event {
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

	private func notify<C: Component>(add component: C) {
		unowned {
			$0.dispatch(ComponentAdded(to: $0))
		}
	}

	private func notify<C: Component>(update newComponent: C, previous previousComponent: C) {
		unowned {
			$0.dispatch(ComponentUpdated(at: $0))
		}
	}

	private func notify<C: Component>(removed component: C) {
		unowned {
			$0.dispatch(ComponentRemoved(from: $0))
		}
	}

	private func notify(removed component: Component) {
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

// MARK: - component tuple access
public extension Entity {

	public func component<A: Component>(_: A.Type) -> A {
		guard let a: A = componentMap[A.uct] as? A else {
			fatalError("Component Mapping Error: '\(A.self)' component was not found in entity '\(self)'")
		}
		return a

	}
	public func components<A: Component, B: Component>(_: A.Type, _: B.Type) -> (A, B) {
		let a: A = component(A.self)
		let b: B = component(B.self)
		return (a, b)
	}
	public func components<A: Component, B: Component, C: Component>(_: A.Type, _: B.Type, _: C.Type) -> (A, B, C) {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		return (a, b, c)
	}
	public func components<A: Component, B: Component, C: Component, D: Component>(_: A.Type, _: B.Type, _: C.Type, _: D.Type) -> (A, B, C, D) {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		return (a, b, c, d)
	}
	public func components<A: Component, B: Component, C: Component, D: Component, E: Component>(_: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type) -> (A, B, C, D, E) {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		let e: E = component(E.self)
		return (a, b, c, d, e)
	}
	public func components<A: Component, B: Component, C: Component, D: Component, E: Component, F: Component>(_: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _: F.Type) -> (A, B, C, D, E, F) {
		let a: A = component(A.self)
		let b: B = component(B.self)
		let c: C = component(C.self)
		let d: D = component(D.self)
		let e: E = component(E.self)
		let f: F = component(F.self)
		return (a, b, c, d, e, f)
	}
}

// MARK: - component closure access
public extension Entity {

	public func component<R, A: Component>(_ closure: (A) -> R) -> R { return closure(component(A.self)) }
	public func components<R, A: Component, B: Component>(_ closure: (A, B) -> R) -> R {
		return closure(component(A.self), component(B.self))
	}
	public func components<R, A: Component, B: Component, C: Component>(_ closure: (A, B, C) -> R) -> R {
		return closure(component(A.self), component(B.self), component(C.self))
	}
	public func components<R, A: Component, B: Component, C: Component, D: Component>(_ closure: (A, B, C, D) -> R) -> R {
		return closure(component(A.self),
					   component(B.self),
					   component(C.self),
					   component(D.self))
	}

	public func components<R, A: Component, B: Component, C: Component, D: Component, E: Component>(_ closure: (A, B, C, D, E) -> R) -> R {
		return closure(component(A.self),
					   component(B.self),
					   component(C.self),
					   component(D.self),
					   component(E.self))
	}

	public func components<R, A: Component, B: Component, C: Component, D: Component, E: Component, F: Component>(_ closure: (A, B, C, D, E, F) -> R) -> R {
		return closure(component(A.self),
					   component(B.self),
					   component(C.self),
					   component(D.self),
					   component(E.self),
					   component(F.self) )
	}
}
