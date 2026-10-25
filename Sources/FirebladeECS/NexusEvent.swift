//
//	NexusEvent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// A marker protocol for all Nexus events.
///
/// The set of events grows with new releases, so the protocol stays open: switch over events with a `default:` case.
///
/// ```swift
/// func nexusEvent(_ event: NexusEvent) {
///     switch event {
///     case let added as ComponentAdded: ...
///     case let modified as ComponentModified: ...
///     default: break
///     }
/// }
/// ```
///
/// Structural events (``EntityCreated``, ``EntityDestroyed``, ``ComponentAdded``, ``ComponentRemoved``,
/// ``FamilyMemberAdded``, ``FamilyMemberRemoved``) are always delivered. Value change events
/// (``ComponentReplaced``, ``ComponentModified``, ``ComponentsModified``) are delivered to delegates that subscribe
/// with ``NexusEventMask/valueChanges``, see ``NexusEventDelegate/subscribedEvents``.
public protocol NexusEvent {}

/// Event triggered when an entity is created.
public struct EntityCreated: NexusEvent {
    /// The identifier of the created entity.
    public let entityId: EntityIdentifier
}

/// Event triggered when an entity is destroyed.
public struct EntityDestroyed: NexusEvent {
    /// The identifier of the destroyed entity.
    public let entityId: EntityIdentifier
}

/// Event triggered when a component is added to an entity.
public struct ComponentAdded: NexusEvent {
    /// The identifier of the added component.
    public let component: ComponentIdentifier
    /// The entity to which the component was added.
    public let toEntity: EntityIdentifier
}

/// Event triggered when a component is removed from an entity.
public struct ComponentRemoved: NexusEvent {
    /// The identifier of the removed component.
    public let component: ComponentIdentifier
    /// The entity from which the component was removed.
    public let from: EntityIdentifier
}

/// Event triggered when an entity becomes a member of a family.
public struct FamilyMemberAdded: NexusEvent {
    /// The entity identifier of the new member.
    public let member: EntityIdentifier
    /// The traits of the family.
    public let toFamily: FamilyTraitSet
}

/// Event triggered when an entity is removed from a family.
public struct FamilyMemberRemoved: NexusEvent {
    /// The entity identifier of the removed member.
    public let member: EntityIdentifier
    /// The traits of the family.
    public let from: FamilyTraitSet
}

/// Event triggered when a component is set on an entity that already has a component of that type.
///
/// A value change event: delivered only to delegates subscribed with ``NexusEventMask/valueChanges``.
public struct ComponentReplaced: NexusEvent {
    /// The identifier of the replaced component.
    public let component: ComponentIdentifier
    /// The entity whose component was replaced.
    public let entityId: EntityIdentifier
}

/// Event triggered after a component of one entity was changed in place.
///
/// A value change event: delivered only to delegates subscribed with ``NexusEventMask/valueChanges``.
public struct ComponentModified: NexusEvent {
    /// The identifier of the modified component.
    public let component: ComponentIdentifier
    /// The entity whose component was modified.
    public let entityId: EntityIdentifier
}

/// Event triggered once after a bulk write pass over all components of a type.
///
/// One event per pass, not one per entity. A value change event: delivered only to delegates subscribed with
/// ``NexusEventMask/valueChanges``.
public struct ComponentsModified: NexusEvent {
    /// The identifier of the modified component type.
    public let component: ComponentIdentifier
    /// The number of components the pass gave write access to.
    public let count: Int
}
