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
	let toEntity: EntityIdentifier
}

public struct ComponentUpdated: ECSEvent {
	let atEnity: EntityIdentifier
}

public struct ComponentRemoved: ECSEvent {
	let component: ComponentIdentifier
	let from: EntityIdentifier
}

public struct FamilyMemberAdded: ECSEvent {
	let member: EntityIdentifier
	let toFamily: FamilyTraitSet
}

public struct FamilyMemberRemoved: ECSEvent {
	let member: EntityIdentifier
	let from: FamilyTraitSet
}

public struct FamilyCreated: ECSEvent {
	let family: FamilyTraitSet
}

public struct FamilyDestroyed: ECSEvent {
	let family: FamilyTraitSet
}
