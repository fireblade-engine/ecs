//
//	Events.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol ECSEvent {}

public struct EntityCreated: ECSEvent {
	public let entityId: EntityIdentifier
}

public struct EntityDestroyed: ECSEvent {
	public let entityId: EntityIdentifier
}

public struct ComponentAdded: ECSEvent {
	public let component: ComponentIdentifier
	public let toEntity: EntityIdentifier
}

public struct ComponentUpdated: ECSEvent {
	public let atEnity: EntityIdentifier
}

public struct ComponentRemoved: ECSEvent {
	public let component: ComponentIdentifier
	public let from: EntityIdentifier
}

public struct FamilyMemberAdded: ECSEvent {
	public let member: EntityIdentifier
	public let toFamily: FamilyTraitSet
}

public struct FamilyMemberRemoved: ECSEvent {
	public let member: EntityIdentifier
	public let from: FamilyTraitSet
}

public struct FamilyCreated: ECSEvent {
	public let family: FamilyTraitSet
}

public struct FamilyDestroyed: ECSEvent {
	public let family: FamilyTraitSet
}
