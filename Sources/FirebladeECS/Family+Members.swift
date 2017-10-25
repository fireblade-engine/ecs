//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

extension Family {
	public func iterateMembers(_ apply: @escaping (EntityIdentifier) -> Void) {
		for entityId in memberIds {
			apply(entityId)
		}
	}
}

extension Family {

	public func iterate<A>(components _: A.Type, _ apply: @escaping (EntityIdentifier, A?) -> Void)
		where A: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				apply(entityId, a)
			}
	}

	public func iterate<A, B>(components _: A.Type, _: B.Type, _ apply: @escaping (EntityIdentifier, A?, B?) -> Void)
		where A: Component, B: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				let b: B? = self.nexus.get(for: entityId)
				apply(entityId, a, b)
			}
	}

	public func iterate<A, B, C>(components _: A.Type, _: B.Type, _: C.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void)
		where A: Component, B: Component, C: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				let b: B? = self.nexus.get(for: entityId)
				let c: C? = self.nexus.get(for: entityId)
				apply(entityId, a, b, c)
			}
	}

	public func iterate<A, B, C, D>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void)
		where A: Component, B: Component, C: Component, D: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				let b: B? = self.nexus.get(for: entityId)
				let c: C? = self.nexus.get(for: entityId)
				let d: D? = self.nexus.get(for: entityId)
				apply(entityId, a, b, c, d)
			}
	}
	public func iterate<A, B, C, D, E>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				let b: B? = self.nexus.get(for: entityId)
				let c: C? = self.nexus.get(for: entityId)
				let d: D? = self.nexus.get(for: entityId)
				let e: E? = self.nexus.get(for: entityId)
				apply(entityId, a, b, c, d, e)
			}
	}

	public func iterate<A, B, C, D, E, F>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _: F.Type,
										  _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?, F?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
			for entityId in memberIds {
				let a: A? = self.nexus.get(for: entityId)
				let b: B? = self.nexus.get(for: entityId)
				let c: C? = self.nexus.get(for: entityId)
				let d: D? = self.nexus.get(for: entityId)
				let e: E? = self.nexus.get(for: entityId)
				let f: F? = self.nexus.get(for: entityId)
				apply(entityId, a, b, c, d, e, f)
			}
	}
}
