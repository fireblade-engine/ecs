//
//  Single.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

public protocol SingleComponent: Component {
    init()
}

public struct Single<A> where A: SingleComponent {
    public let nexus: Nexus
    public let traits: FamilyTraitSet
    public let entityId: EntityIdentifier
}

extension Single: Equatable {
    public static func == (lhs: Single<A>, rhs: Single<A>) -> Bool {
        lhs.traits == rhs.traits &&
            lhs.entityId == rhs.entityId &&
            lhs.nexus === rhs.nexus
    }
}

extension Single where A: SingleComponent {
    @inlinable public var component: A {
        // Since we guarantee that the component will always be present by managing the complete lifecycle of the entity
        // and component assignment we may unsafelyUnwrap here.
        // Since components will always be of reference type (class) we may use unsafeDowncast here for performance reasons.
        nexus.get(unsafeComponentFor: entityId)
    }

    public var entity: Entity {
        nexus.get(entity: entityId).unsafelyUnwrapped
    }
}

extension Nexus {
    public func single<S>(_ component: S.Type) -> Single<S> where S: SingleComponent {
        let family = self.family(requires: S.self)
        precondition(family.count <= 1, "Singleton count of \(S.self) must be 0 or 1: \(family.count)")
        let entityId: EntityIdentifier
        if family.isEmpty {
            entityId = createEntity(with: S()).identifier
        } else {
            entityId = family.memberIds.first.unsafelyUnwrapped
        }
        return Single<S>(nexus: self, traits: family.traits, entityId: entityId)
    }
}
