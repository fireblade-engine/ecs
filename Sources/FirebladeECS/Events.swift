//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityCreated: Event {
	let entityId: EntityIdentifier
}

public struct EntityDestroyed: Event {
	let entityId: EntityIdentifier
}

public struct ComponentAdded: Event {
	let component: ComponentIdentifier
	let to: EntityIdentifier
}

public struct ComponentUpdated: Event {
	let at: EntityIdentifier
}

public struct ComponentRemoved: Event {
	let component: ComponentIdentifier
	let from: EntityIdentifier
}

struct FamilyMemberAdded: Event {
	let member: EntityIdentifier
	let to: FamilyTraitSet
}

struct FamilyMemberRemoved: Event {
	let member: EntityIdentifier
	let from: FamilyTraitSet
}

struct FamilyCreated: Event {
	let family: FamilyTraitSet
}

struct FamilyDestroyed: Event {
	let family: FamilyTraitSet
}
