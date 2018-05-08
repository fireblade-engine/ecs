//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

public extension Family {
	func iterate(entities apply: @escaping (EntityIdentifier) -> Void) {
        for entityId: EntityIdentifier in memberIds {
			apply(entityId)
		}
	}

	func iterate<A>(components _: A.Type, _ apply: @escaping (EntityIdentifier, A?) -> Void)
		where A: Component {
            for entityId: EntityIdentifier in memberIds {
				let compA: A? = nexus?.get(for: entityId)
				apply(entityId, compA)
			}
	}

	func iterate<A, B>(components _: A.Type, _: B.Type, _ apply: @escaping (EntityIdentifier, A?, B?) -> Void)
		where A: Component, B: Component {
			for entityId: EntityIdentifier in memberIds {
				let compA: A? = nexus?.get(for: entityId)
				let compB: B? = nexus?.get(for: entityId)
				apply(entityId, compA, compB)
			}
	}

	func iterate<A, B, C>(components _: A.Type, _: B.Type, _: C.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void)
		where A: Component, B: Component, C: Component {
			for entityId: EntityIdentifier in memberIds {
				let compA: A? = nexus?.get(for: entityId)
				let compB: B? = nexus?.get(for: entityId)
				let compC: C? = nexus?.get(for: entityId)
				apply(entityId, compA, compB, compC)
			}
	}

	func iterate<A, B, C, D>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
		for entityId: EntityIdentifier in memberIds {
			let compA: A? = nexus?.get(for: entityId)
			let compB: B? = nexus?.get(for: entityId)
			let compC: C? = nexus?.get(for: entityId)
			let compD: D? = nexus?.get(for: entityId)
			apply(entityId, compA, compB, compC, compD)
		}
	}

    // swiftlint:disable:next function_parameter_count
	func iterate<A, B, C, D, E>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component {
			for entityId: EntityIdentifier in memberIds {
				let compA: A? = nexus?.get(for: entityId)
				let compB: B? = nexus?.get(for: entityId)
				let compC: C? = nexus?.get(for: entityId)
				let compD: D? = nexus?.get(for: entityId)
				let compE: E? = nexus?.get(for: entityId)
				apply(entityId, compA, compB, compC, compD, compE)
			}
	}

	func iterate<A>(_ apply: @escaping (EntityIdentifier, A?) -> Void) where A: Component {
		iterate(components: A.self, apply)
	}

	func iterate<A, B>(_ apply: @escaping (EntityIdentifier, A?, B?) -> Void) where A: Component, B: Component {
		iterate(components: A.self, B.self, apply)
	}

	func iterate<A, B, C>(_ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void) where A: Component, B: Component, C: Component {
		iterate(components: A.self, B.self, C.self, apply)
	}

	func iterate<A, B, C, D>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
		iterate(components: A.self, B.self, C.self, D.self, apply)
	}

	func iterate<A, B, C, D, E>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component {
		iterate(components: A.self, B.self, C.self, D.self, E.self, apply)
	}
}
