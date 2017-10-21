//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

extension Family {
	public func iterateMembers(_ apply: @escaping (EntityIdentifier, () -> Entity) -> Void) {
		memberIds.forEach { (entityId: EntityIdentifier) -> Void in
			func getEntity() -> Entity {
				return nexus.get(entity: entityId)
			}
			apply(entityId, getEntity)
		}
	}
}

extension Family {

	public func iterate<A>(components _: A.Type, _ apply: @escaping (() -> Entity, () -> A?) -> Void)
		where A: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent)
		}
	}

	public func iterate<A, B>(components _: A.Type, _: B.Type, _ apply: @escaping (() -> Entity, () -> A?, () -> B?) -> Void)
		where A: Component, B: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C>(components _: A.Type, _: B.Type, _: C.Type, _ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?) -> Void)
		where A: Component, B: Component, C: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C, D>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?) -> Void)
		where A: Component, B: Component, C: Component, D: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent)
		}
	}
	public func iterate<A, B, C, D, E>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C, D, E, F>(components _: A.Type, _: B.Type, _: C.Type, _: D.Type, _: E.Type, _: F.Type,
								   _ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?, () -> F?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent, getComponent, getComponent)
		}
	}
}

extension Family {

	public func iterate<A>(_ apply: @escaping (() -> Entity, () -> A?) -> Void) where A: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent)
		}
	}

	public func iterate<A, B>(_ apply: @escaping (() -> Entity, () -> A?, () -> B?) -> Void)
		where A: Component, B: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C>(_ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?) -> Void)
		where A: Component, B: Component, C: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C, D>(_ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?) -> Void)
		where A: Component, B: Component, C: Component, D: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C, D, E>(_ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent, getComponent)
		}
	}

	public func iterate<A, B, C, D, E, F>(_ apply: @escaping (() -> Entity, () -> A?, () -> B?, () -> C?, () -> D?, () -> E?, () -> F?) -> Void)
		where A: Component, B: Component, C: Component, D: Component, E: Component, F: Component {
		iterateMembers { (entityId, getEntityInstance) in
			func getComponent<Z>() -> Z? where Z: Component {
				return self.nexus.get(component: Z.identifier, for: entityId) as? Z
			}
			apply(getEntityInstance, getComponent, getComponent, getComponent, getComponent, getComponent, getComponent)
		}
	}

}
