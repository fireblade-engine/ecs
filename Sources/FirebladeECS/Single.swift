//
//  Single.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

public protocol SingleComponent: Component {
    init()
}

public struct Single<A: SingleComponent> {
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
        nexus.get(unsafe: entityId)
    }

    public var entity: Entity {
        Entity(nexus: nexus, id: entityId)
    }
}

extension Nexus {
    public func single<S: SingleComponent>(_ component: S.Type) -> Single<S> {
        let family = family(requires: S.self)
        precondition(family.count <= 1, "Singleton count of \(S.self) must be 0 or 1: \(family.count)")
        let entityId: EntityIdentifier = if family.isEmpty {
            createEntity(with: S()).identifier
        } else {
            family.memberIds.first.unsafelyUnwrapped
        }
        return Single<S>(nexus: self, traits: family.traits, entityId: entityId)
    }
}
