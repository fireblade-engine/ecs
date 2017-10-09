//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityCreated: Event {
	let entity: Entity
}

public struct EntityDestroyed: Event {
	let entity: Entity
}

public struct ComponentAdded: Event {
	//let component: Component
	let to: Entity
}

public struct ComponentUpdated: Event {
	//let component: Component
	//let previous: Component
	let at: Entity
}

public struct ComponentRemoved: Event {
	//let component: Component
	let from: Entity
}

struct FamilyMemberAdded: Event {
	let member: Entity
	let to: Family
}

struct FamilyMemberUpdated: Event {
	let newMember: Entity
	let oldMember: Entity
	let `in`: Family
}

struct FamilyMemberRemoved: Event {
	let member: Entity
	let from: Family
}

struct FamilyCreated: Event {
	let family: Family
}

struct FamilyDestroyed: Event {
	let family: Family
}
