//
//  Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public struct EntityCreated: Event {
	unowned let entity: Entity
}

public struct EntityDestroyed: Event {
	unowned let entity: Entity
}

public struct ComponentAdded: Event {
	//let component: Component
	unowned let to: Entity
}

public struct ComponentUpdated: Event {
	//let component: Component
	//let previous: Component
	unowned let at: Entity
}

public struct ComponentRemoved: Event {
	//let component: Component
	unowned let from: Entity
}

struct FamilyMemberAdded: Event {
	unowned let member: Entity
	unowned let to: Family
}

struct FamilyMemberUpdated: Event {
	unowned let newMember: Entity
	unowned let oldMember: Entity
	unowned let `in`: Family
}

struct FamilyMemberRemoved: Event {
	unowned let member: Entity
	unowned let from: Family
}

struct FamilyCreated: Event {
	unowned let family: Family
}

struct FamilyDestroyed: Event {
	unowned let family: Family
}
