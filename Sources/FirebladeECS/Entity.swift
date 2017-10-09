//
//  Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public final class Entity: UniqueEntityIdentifiable {
	public let uei: UEI

	fileprivate var componentMap: [UCT:Component]

	private init(uei: UEI) {
		self.uei = uei
		componentMap = [UCT: Component]()
		componentMap.reserveCapacity(2)
	}

	convenience public init() {
		let uei: UEI = UEI.next
		self.init(uei: uei)
		defer {
			notify(init: unownedRef)
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
		fatalError()
	}

	public final var hasComponents: Bool { return !componentMap.isEmpty }

}

// MARK: - push component(s)
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
		notify(destroyed: unownedRef)
	}
}

extension Entity: EventSender {

	private unowned var unownedRef: Entity {
		return self
	}

	private func notify(init: Entity) {
		dispatch(event: EntityCreated(entity: unownedRef))
	}

	private func notify<C: Component>(add component: C) {
		dispatch(event: ComponentAdded(component: component, to: unownedRef))
	}

	private func notify<C: Component>(update newComponent: C, previous previousComponent: C) {
		dispatch(event: ComponentUpdated(component: newComponent, previous: previousComponent, at: unownedRef))
	}

	private func notify<C: Component>(removed component: C) {
		dispatch(event: ComponentRemoved(component: component, from: unownedRef))
	}

	private func notify(removed component: Component) {
		dispatch(event: ComponentRemoved(component: component, from: unownedRef))
	}

	private func notify(destroyed: Entity) {
		dispatch(event: EntityDestroyed(entity: unownedRef))
	}

}

// MARK: - debugging and string representation
/*
extension Entity: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String { return "Entity\(stringifyLabel())[\(uid)]" }
	public var debugDescription: String {
		let comps: String = self.componentMap.map { (_: ComponentType, comp: Component) in
			return comp.debugDescription
			}.joined(separator: ",")
		return "\(self.description){ \(comps) }"
	}
}
extension Entity: CustomPlaygroundQuickLookable {
	public var customPlaygroundQuickLook: PlaygroundQuickLook {
		return .text(self.debugDescription)
	}
}
*/
