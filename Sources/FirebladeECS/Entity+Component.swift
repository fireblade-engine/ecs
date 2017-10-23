//
//  Entity+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.10.17.
//

// MARK: - get components
public extension Entity {

	public final func get<C>() -> C? where C: Component {
		return nexus.get(for: identifier)
	}

	public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
		return nexus.get(for: identifier)
	}

	public func getComponent<A>() -> () -> A? where A: Component {
		func getComponentFunc() -> A? {
			return get(component: A.self)
		}
		return getComponentFunc
	}

	public func get<A, B>(components _: A.Type, _: B.Type) -> (A, B) where A: Component, B: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		return (a, b)
	}
	public func get<A, B, C>(components _: A.Type, _: B.Type, _: C.Type) -> (A, B, C) where A: Component, B: Component, C: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		let c: C = get(component: C.self)!
		return (a, b, c)
	}
	public func get<A, B, C, D>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type) -> (A, B, C, D) where A: Component, B: Component, C: Component, D: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		let c: C = get(component: C.self)!
		let d: D = get(component: D.self)!
		return (a, b, c, d)
	}
	public func get<A, B, C, D, E>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type) -> (A, B, C, D, E) where A: Component, B: Component, C: Component, D: Component, E: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		let c: C = get(component: C.self)!
		let d: D = get(component: D.self)!
		let e: E = get(component: E.self)!
		return (a, b, c, d, e)
	}
	public func get<A, B, C, D, E, F>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _: F.Type) -> (A, B, C, D, E, F) where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
		let a: A = get(component: A.self)!
		let b: B = get(component: B.self)!
		let c: C = get(component: C.self)!
		let d: D = get(component: D.self)!
		let e: E = get(component: E.self)!
		let f: F = get(component: F.self)!
		return (a, b, c, d, e, f)
	}
}
