//
//  Family+Members.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.10.17.
//

public protocol FamilyMemberIterable {

    func iterate<A>(_ apply: @escaping (A?) -> Void) where A: Component
    func iterate<A, B>(_ apply: @escaping (A?, B?) -> Void) where A: Component, B: Component
    func iterate<A, B, C>(_ apply: @escaping (A?, B?, C?) -> Void) where A: Component, B: Component, C: Component
    func iterate<A, B, C, D>(_ apply: @escaping (A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component
    func iterate<A, B, C, D, E>(_ apply: @escaping (A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component

    func iterate(_ apply: @escaping (EntityIdentifier) -> Void)
    func iterate<A>(_ apply: @escaping (EntityIdentifier, A?) -> Void) where A: Component
    func iterate<A, B>(_ apply: @escaping (EntityIdentifier, A?, B?) -> Void) where A: Component, B: Component
    func iterate<A, B, C>(_ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void) where A: Component, B: Component, C: Component
    func iterate<A, B, C, D>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component
    func iterate<A, B, C, D, E>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component

    func iterate(_ apply: @escaping (Entity?) -> Void)
    func iterate<A>(_ apply: @escaping (Entity?, A?) -> Void) where A: Component
    func iterate<A, B>(_ apply: @escaping (Entity?, A?, B?) -> Void) where A: Component, B: Component
    func iterate<A, B, C>(_ apply: @escaping (Entity?, A?, B?, C?) -> Void) where A: Component, B: Component, C: Component
    func iterate<A, B, C, D>(_ apply: @escaping (Entity?, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component
    func iterate<A, B, C, D, E>(_ apply: @escaping (Entity?, A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component
}

// swiftlint:disable large_tuple
private protocol FamilyMemberComponentsGetterProtocol {
    func components<A>(_ entityId: EntityIdentifier) -> (A?) where A: Component
    func components<A, B>(_ entityId: EntityIdentifier) -> (A?, B?) where A: Component, B: Component
    func components<A, B, C>(_ entityId: EntityIdentifier) -> (A?, B?, C?) where A: Component, B: Component, C: Component
    func components<A, B, C, D>(_ entityId: EntityIdentifier) -> (A?, B?, C?, D?) where A: Component, B: Component, C: Component, D: Component
    func components<A, B, C, D, E>(_ entityId: EntityIdentifier) -> (A?, B?, C?, D?, E?) where A: Component, B: Component, C: Component, D: Component, E: Component
}

extension Family: FamilyMemberIterable {

    public final func iterate<A>(_ apply: @escaping (A?) -> Void) where A: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?) = components(entityId)
            apply(comps)
        }
    }

    public final func iterate<A, B>(_ apply: @escaping (A?, B?) -> Void) where A: Component, B: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?) = components(entityId)
            apply(comps.0, comps.1)
        }
    }

    public final func iterate<A, B, C>(_ apply: @escaping (A?, B?, C?) -> Void) where A: Component, B: Component, C: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?) = components(entityId)
            apply(comps.0, comps.1, comps.2)
        }
    }

    public final func iterate<A, B, C, D>(_ apply: @escaping (A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?, D?) = components(entityId)
            apply(comps.0, comps.1, comps.2, comps.3)
        }
    }

    public final func iterate<A, B, C, D, E>(_ apply: @escaping (A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?, D?, E?) = components(entityId)
            apply(comps.0, comps.1, comps.2, comps.3, comps.4)
        }
    }

    public final func iterate(_ apply: @escaping (EntityIdentifier) -> Void) {
        for entityId: EntityIdentifier in memberIds {
            apply(entityId)
        }
    }

    public final func iterate<A>(_ apply: @escaping (EntityIdentifier, A?) -> Void) where A: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?) = components(entityId)
            apply(entityId, comps)
        }
    }

    public final func iterate<A, B>(_ apply: @escaping (EntityIdentifier, A?, B?) -> Void) where A: Component, B: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?) = components(entityId)
            apply(entityId, comps.0, comps.1)
        }
    }

    public final func iterate<A, B, C>(_ apply: @escaping (EntityIdentifier, A?, B?, C?) -> Void) where A: Component, B: Component, C: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?) = components(entityId)
            apply(entityId, comps.0, comps.1, comps.2)
        }
    }

    public final func iterate<A, B, C, D>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?, D?) = components(entityId)
            apply(entityId, comps.0, comps.1, comps.2, comps.3)
        }
    }

    public final func iterate<A, B, C, D, E>(_ apply: @escaping (EntityIdentifier, A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component {
        for entityId: EntityIdentifier in memberIds {
            let comps: (A?, B?, C?, D?, E?) = components(entityId)
            apply(entityId, comps.0, comps.1, comps.2, comps.3, comps.4)
        }
    }

    public final func iterate(_ apply: @escaping (Entity?) -> Void) {
        for entityId: EntityIdentifier in memberIds {
            apply(nexus?.get(entity: entityId))
        }
    }

    public final func iterate<A>(_ apply: @escaping (Entity?, A?) -> Void) where A: Component {
        for entityId: EntityIdentifier in memberIds {
            let entity: Entity? = nexus?.get(entity: entityId)
            let comps: (A?) = components(entityId)
            apply(entity, comps)
        }
    }

    public final func iterate<A, B>(_ apply: @escaping (Entity?, A?, B?) -> Void) where A: Component, B: Component {
        for entityId: EntityIdentifier in memberIds {
            let entity: Entity? = nexus?.get(entity: entityId)
            let comps: (A?, B?) = components(entityId)
            apply(entity, comps.0, comps.1)
        }
    }

    public final func iterate<A, B, C>(_ apply: @escaping (Entity?, A?, B?, C?) -> Void) where A: Component, B: Component, C: Component {
        for entityId: EntityIdentifier in memberIds {
            let entity: Entity? = nexus?.get(entity: entityId)
            let comps: (A?, B?, C?) = components(entityId)
            apply(entity, comps.0, comps.1, comps.2)
        }
    }

    public final func iterate<A, B, C, D>(_ apply: @escaping (Entity?, A?, B?, C?, D?) -> Void) where A: Component, B: Component, C: Component, D: Component {
        for entityId: EntityIdentifier in memberIds {
            let entity: Entity? = nexus?.get(entity: entityId)
            let comps: (A?, B?, C?, D?) = components(entityId)
            apply(entity, comps.0, comps.1, comps.2, comps.3)
        }
    }

    public final func iterate<A, B, C, D, E>(_ apply: @escaping (Entity?, A?, B?, C?, D?, E?) -> Void) where A: Component, B: Component, C: Component, D: Component, E: Component {
        for entityId: EntityIdentifier in memberIds {
            let entity: Entity? = nexus?.get(entity: entityId)
            let comps: (A?, B?, C?, D?, E?) = components(entityId)
            apply(entity, comps.0, comps.1, comps.2, comps.3, comps.4)
        }
    }

}

// swiftlint:disable large_tuple
extension Family: FamilyMemberComponentsGetterProtocol {

    func components<A>(_ entityId: EntityIdentifier) -> (A?) where A: Component {
        let compA: A? = nexus?.get(for: entityId)
        return (compA)
    }

    func components<A, B>(_ entityId: EntityIdentifier) -> (A?, B?) where A: Component, B: Component {
        let compA: A? = nexus?.get(for: entityId)
        let compB: B? = nexus?.get(for: entityId)
        return (compA, compB)
    }

    func components<A, B, C>(_ entityId: EntityIdentifier) -> (A?, B?, C?) where A: Component, B: Component, C: Component {
        let compA: A? = nexus?.get(for: entityId)
        let compB: B? = nexus?.get(for: entityId)
        let compC: C? = nexus?.get(for: entityId)
        return (compA, compB, compC)
    }

    final func components<A, B, C, D>(_ entityId: EntityIdentifier) -> (A?, B?, C?, D?) where A: Component, B: Component, C: Component, D: Component {
        let compA: A? = nexus?.get(for: entityId)
        let compB: B? = nexus?.get(for: entityId)
        let compC: C? = nexus?.get(for: entityId)
        let compD: D? = nexus?.get(for: entityId)
        return (compA, compB, compC, compD)
    }

    final func components<A, B, C, D, E>(_ entityId: EntityIdentifier) -> (A?, B?, C?, D?, E?) where A: Component, B: Component, C: Component, D: Component, E: Component {
        let compA: A? = nexus?.get(for: entityId)
        let compB: B? = nexus?.get(for: entityId)
        let compC: C? = nexus?.get(for: entityId)
        let compD: D? = nexus?.get(for: entityId)
        let compE: E? = nexus?.get(for: entityId)
        return (compA, compB, compC, compD, compE)
    }
}
