//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//
/*
// TODO: is this needed?
struct FamilyMemberAdded: Event {
	let entity: Entity
	let family: Family
}
// TODO: is this needed?
struct FamilyMemberRemoved: Event {
	let entity: Entity
	let family: Family
}

struct FamilyCreated: Event {
	let family: Family
}

struct FamilyDestroyed: Event {
	//TODO: family
}

public final class Family: EventSender, EventHandler {

	// members of this Family must conform to:
	let required: Set<ComponentType>
	let excluded: Set<ComponentType>

	public private(set) var members: ContiguousArray<Entity>

	public convenience init(requiresAll required: ComponentType...) {
		self.init(requiresAll: required, excludesAll: [])
	}

	public init(requiresAll required: [ComponentType], excludesAll excluded: [ComponentType]) {
		self.required = Set<ComponentType>(required)
		self.excluded = Set<ComponentType>(excluded)

		self.members = []

		subscribe(event: handleComponentAddedToEntity)
		subscribe(event: handleComponentRemovedFromEntity)

		dispatch(event: FamilyCreated(family: self))
	}

	deinit {

		//TODO: optimize for large sets
		//TODO: dispatch entity removed event
		self.members.removeAll()

		unsubscribe(event: handleComponentAddedToEntity)
		unsubscribe(event: handleComponentRemovedFromEntity)

		dispatch(event: FamilyDestroyed())
	}

	final func handleComponentAddedToEntity(event: ComponentAdded) {
		//TODO: optimize by more specific comparison
		self.update(familyMembership: event.toEntity)
	}
	final func handleComponentRemovedFromEntity(event: ComponentRemoved) {
		//TODO: optimize by more specific comparison
		self.update(familyMembership: event.fromEntity)
	}

	final func matches(familyRequirements entity: Entity) -> Bool {
		return entity.contains(all: required) && entity.contains(none: excluded)
	}

	final func contains(entity: Entity) -> Bool {
		return self.members.contains(where: { $0.uid == entity.uid })
	}
	final func indexOf(entity: Entity) -> Int? {
		return self.members.index(where: { $0.uid == entity.uid })
	}

	final func update(familyMemberships entities: ContiguousArray<Entity>) {
		//TODO: optimize for large sets
		entities.forEach { self.update(familyMembership:$0) }
	}

	private final func update(familyMembership entity: Entity) {

		let NEW: Int = -1
		let isMatch: Bool = matches(familyRequirements: entity)
		let index: Int = indexOf(entity: entity) ?? NEW
		let isNew: Bool = index == NEW

		switch (isMatch, isNew) {
		case (true, true): // isMatch && new -> add
			add(toFamily: entity)
			return

		case (false, false): // noMatch && isPart -> remove
			remove(entityAtIndex: index)
			return

		default:
			return
		}
	}

	private final func add(toFamily entity: Entity) {
		self.members.append(entity)
		dispatch(event: FamilyMemberAdded(entity: entity, family: self))
	}

	private final func remove(entityAtIndex index: Int) {
		let removedEntity: Entity = self.members.remove(at: index)
		dispatch(event: FamilyMemberRemoved(entity: removedEntity, family: self))
	}
}
*/
