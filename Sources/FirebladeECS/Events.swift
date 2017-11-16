//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//
public protocol ECSEvent {}
public struct EntityCreated: ECSEvent {
	let entityId: EntityIdentifier
}

public struct EntityDestroyed: ECSEvent {
	let entityId: EntityIdentifier
}

public struct ComponentAdded: ECSEvent {
	let component: ComponentIdentifier
	let to: EntityIdentifier
}

public struct ComponentUpdated: ECSEvent {
	let at: EntityIdentifier
}

public struct ComponentRemoved: ECSEvent {
	let component: ComponentIdentifier
	let from: EntityIdentifier
}

struct FamilyMemberAdded: ECSEvent {
	let member: EntityIdentifier
	let to: FamilyTraitSet
}

struct FamilyMemberRemoved: ECSEvent {
	let member: EntityIdentifier
	let from: FamilyTraitSet
}

struct FamilyCreated: ECSEvent {
	let family: FamilyTraitSet
}

struct FamilyDestroyed: ECSEvent {
	let family: FamilyTraitSet
}
