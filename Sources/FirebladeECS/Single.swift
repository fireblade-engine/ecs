//
//  Single.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

/// A protocol defining a component that is intended to be a singleton.
///
/// A single component must be default initializable.
public protocol SingleComponent: Component {
    /// Creates a new instance of the component.
    init()
}

/// A wrapper for accessing a single component (singleton) within the ECS.
///
/// Use `Single` to access a component that is guaranteed to have at most one instance in the ECS.
public struct Single<A: SingleComponent> {
    /// The Nexus instance managing this component.
    public let nexus: Nexus
    /// The family traits associated with this single component.
    public let traits: FamilyTraitSet
    /// The entity identifier of the singleton entity.
    public let entityId: EntityIdentifier
}

extension Single: Equatable {
    /// Returns a Boolean value indicating whether two single component accessors are equal.
    /// - Parameters:
    ///   - lhs: A single component accessor to compare.
    ///   - rhs: Another single component accessor to compare.
    /// - Complexity: O(1)
    public static func == (lhs: Single<A>, rhs: Single<A>) -> Bool {
        lhs.traits == rhs.traits &&
            lhs.entityId == rhs.entityId &&
            lhs.nexus === rhs.nexus
    }
}

extension Single where A: SingleComponent {
    /// The singleton component instance.
    ///
    /// - Note: This property unsafely unwraps the component for performance, assuming the component always exists.
    /// - Complexity: O(1)
    @inlinable public var component: A {
        // Since we guarantee that the component will always be present by managing the complete lifecycle of the entity
        // and component assignment we may unsafelyUnwrap here.
        // Since components will always be of reference type (class) we may use unsafeDowncast here for performance reasons.
        nexus.get(unsafe: entityId)
    }

    /// The entity associated with this singleton component.
    /// - Complexity: O(1)
    public var entity: Entity {
        Entity(nexus: nexus, id: entityId)
    }
}

extension Nexus {
    /// Retrieves or creates a singleton accessor for the specified component type.
    ///
    /// - Parameter component: The type of the single component.
    /// - Returns: A `Single` accessor for the component.
    /// - Precondition: The count of entities with this component must be 0 or 1.
    /// - Complexity: O(M) where M is the number of families.
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
