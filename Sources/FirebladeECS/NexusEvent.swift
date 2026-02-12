//
//	NexusEvent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// A marker protocol for all Nexus events.
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
