//
//  Entity+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.10.17.
//

// MARK: - get components
public extension Entity {

	final func get<C>() -> C? where C: Component {
		return nexus.get(for: identifier)
	}

	func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
		return nexus.get(for: identifier)
	}

	func getComponent<A>() -> () -> A? where A: Component {
		func getComponentFunc() -> A? {
			return get(component: A.self)
		}
		return getComponentFunc
	}

	func get<A, B>(components _: A.Type, _: B.Type) -> (A, B) where A: Component, B: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		return (a, b)
	}

	func get<A, B, C>(components _: A.Type, _: B.Type, _: C.Type) -> (A, B, C) where A: Component, B: Component, C: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		let c: C = get(component: C.self)!
		return (a, b, c)
	}
}
