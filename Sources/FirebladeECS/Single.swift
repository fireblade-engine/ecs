//
//  Single.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

public protocol SingleComponent: Component {
    init()
}

public extension Nexus {
    func single<S>(_ component: S.Type) -> Single<S> where S: SingleComponent {
        let family = self.family(requires: S.self)
        precondition(family.count <= 1, "Singleton count of \(S.self) must be 0 or 1: \(family.count)")
        let entityId: EntityIdentifier
        if family.isEmpty {
            entityId = create(entity: "\(S.self)", with: S()).identifier
        } else {
            entityId = family.memberIds.first.unsafelyUnwrapped
        }
        return Single<S>(nexus: self, traits: family.traits, entityId: entityId)
    }
}

public struct Single<A>: Equatable where A: SingleComponent {
    public let nexus: Nexus
    public let traits: FamilyTraitSet
    public let entityId: EntityIdentifier
}

public extension Single where A: SingleComponent {
    @inlinable var component: A {
        /// Since we guarantee that the component will always be present by managing the complete lifecycle of the entity
        /// and component assignment we may unsafelyUnwrap here.
        /// Since components will allways be of reference type (class) we may use unsafeDowncast here for performance reasons.
        return nexus.get(unsafeComponentFor: entityId)
    }

    var entity: Entity {
        return nexus.get(entity: entityId).unsafelyUnwrapped
    }
}
