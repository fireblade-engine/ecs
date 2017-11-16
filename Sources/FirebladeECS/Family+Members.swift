//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

public extension Family {
	func iterate(entities apply: @escaping (EntityIdentifier) -> Void) {
		for entityId in memberIds {
			apply(entityId)
		}
	}

	func iterate<A>(components _: A.Type, _ apply: @escaping (EntityIdentifier, A?) -> Void)
		where A: Component {
			for entityId in memberIds {
				let a: A? = nexus?.get(for: entityId)
				apply(entityId, a)
			}
	}

	func iterate<A, B>(components _: A.Type, _: B.Type, _ apply: @escaping (EntityIdentifier, A?, B?) -> Void)
		where A: Component, B: Component {
			for entityId in memberIds {
				let a: A? = nexus?.get(for: entityId)
				let b: B? = nexus?.get(for: entityId)
				apply(entityId, a, b)
			}
	}

	func iterate<A, B, C>(components _: A.Type, _: B.Type, _: C.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void)
		where A: Component, B: Component, C: Component {
			for entityId in memberIds {
				let a: A? = nexus?.get(for: entityId)
				let b: B? = nexus?.get(for: entityId)
				let c: C? = nexus?.get(for: entityId)
				apply(entityId, a, b, c)
			}
	}

	func iterate<A, B, C, D>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
		for entityId in memberIds {
			let a: A? = nexus?.get(for: entityId)
			let b: B? = nexus?.get(for: entityId)
			let c: C? = nexus?.get(for: entityId)
			let d: D? = nexus?.get(for: entityId)
			apply(entityId, a, b, c, d)
		}
	}

	func iterate<A, B, C, D, E>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component {
			for entityId in memberIds {
				let a: A? = nexus?.get(for: entityId)
				let b: B? = nexus?.get(for: entityId)
				let c: C? = nexus?.get(for: entityId)
				let d: D? = nexus?.get(for: entityId)
				let e: E? = nexus?.get(for: entityId)
				apply(entityId, a, b, c, d, e)
			}
	}

}
