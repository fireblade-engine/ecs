//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

public protocol FamilyIterable {
	func forEachMember(_ applyToMember: (Entity) -> Void)
	func forEachMember<A>(_ applyToMember: (Entity, A) -> Void) where A: Component
	func forEachMember<A, B>(_ applyToMember: (Entity, A, B) -> Void) where A: Component, B: Component
	func forEachMember<A, B, C>(_ applyToMember: (Entity, A, B, C) -> Void) where A: Component, B: Component, C: Component
	func forEachMember<A, B, C, D>(_ applyToMember: (Entity, A, B, C, D) -> Void) where A: Component, B: Component, C: Component, D: Component
	func forEachMember<A, B, C, D, E>(_ applyToMember: (Entity, A, B, C, D, E) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component
	func forEachMember<A, B, C, D, E, F>(_ applyToMember: (Entity, A, B, C, D, E, F) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component

}

extension Family/*: FamilyIterable*/ {
	public func forEachMember(_ applyToMember: (Entity) -> Void) {
		members.forEach { applyToMember(nexus.get(entity: $0)!) }
	}

	public func forEachMember<A>(_ applyToMember: (Entity, () -> A?) -> Void) where A: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component())
		}
	}

	public func forEachMember<A, B>(_ applyToMember: (Entity, () -> A?, () -> B?) -> Void) where A: Component, B: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component(), entity.component())
		}
	}

	public func forEachMember<A, B, C>(_ applyToMember: (Entity, () -> A?, () -> B?, () -> C?) -> Void) where A: Component, B: Component, C: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component(), entity.component(), entity.component())
		}
	}

	public func forEachMember<A, B, C, D>(_ applyToMember: (Entity, () -> A?, () -> B?, () -> C?, () -> D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component(), entity.component(), entity.component(), entity.component())
		}
	}

	public func forEachMember<A, B, C, D, E>(_ applyToMember: (Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component(), entity.component(), entity.component(), entity.component(), entity.component())
		}
	}

	public func forEachMember<A, B, C, D, E, F>(_ applyToMember: (Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?, () -> F?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
		forEachMember { (entity: Entity) in
			applyToMember(entity, entity.component(), entity.component(), entity.component(), entity.component(), entity.component(), entity.component())
		}
	}

}
