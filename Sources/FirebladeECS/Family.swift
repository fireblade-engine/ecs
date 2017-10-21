//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {
	internal var nexus: Nexus
	// members of this Family must conform to these traits
	public let traits: FamilyTraitSet

	internal init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.nexus = nexus
		self.traits = traits
	}

	deinit {

	}
}

extension Family {
	public final func canBecomeMember(_ entity: Entity) -> Bool {
		return nexus.canBecomeMember(entity, in: self)
	}

	public final func isMember(_ entity: Entity) -> Bool {
		return nexus.isMember(entity, in: self)
	}

	internal var members: LazyMapCollection<LazyFilterCollection<LazyMapCollection<EntityIdSet, Entity?>>, Entity> {
		return nexus.members(of: self)
	}
	internal var memberIds: EntityIdSet {
		return nexus.members(of: self)
	}
}

// MARK: - member iterator
extension Family {
	/*
	func makeIterator<A>() -> AnyIterator<(Entity, A)> where A: Component {
		var members = self.members.makeIterator()
		return AnyIterator<(Entity, A)> { [unowned self] in
			let entityId: EntityIdentifier = members.next()!
			let entity: Entity = self.nexus.get(entity: entityId)!
			let a: A = entity.get()!
			return (entity, a)
		}
	}

	func makeIterator<A, B>() -> AnyIterator<(Entity, A, B)> where A: Component, B: Component {
		var members = self.members.makeIterator()
		return AnyIterator<(Entity, A, B)> { [unowned self] in
			let entityId: EntityIdentifier = members.next()!
			let entity: Entity = self.nexus.get(entity: entityId)!
			let a: A = entity.get()!
			let b: B = entity.get()!
			return (entity, a, b)
		}
	}

	func makeIterator<A, B, C>() -> AnyIterator<(Entity, A, B, C)> where A: Component, B: Component, C: Component {
		var members = self.members.makeIterator()
		return AnyIterator<(Entity, A, B, C)> { [unowned self] in
			let entityId: EntityIdentifier = members.next()!
			let entity: Entity = self.nexus.get(entity: entityId)!
			let a: A = entity.get()!
			let b: B = entity.get()!
			let c: C = entity.get()!
			return (entity, a, b, c)
		}
	}
	*/
}

/*
// MARK: - Equatable
extension Family: Equatable {
	public static func ==(lhs: Family, rhs: Family) -> Bool {
		return lhs.traits == rhs.traits
	}
}

// MARK: - Hashable
extension Family: Hashable {
	public var hashValue: Int {
		return traits.hashValue
	}
}
*/
/*
// MARK: - event dispatcher
extension Family: EventDispatcher {
	public func dispatch<E>(_ event: E) where E: Event {
		dispatcher.dispatch(event)
	}

	fileprivate func notifyCreated() {
		dispatch(FamilyCreated(family: traits))
	}

	fileprivate func notify(added newEntity: EntityIdentifier) {
		dispatch(FamilyMemberAdded(member: newEntity, to: traits))
	}

	fileprivate func notify(removed removedEntity: EntityIdentifier) {
		dispatch(FamilyMemberRemoved(member: removedEntity, from: traits))
	}

	fileprivate func notifyDestroyed() {
		dispatch(FamilyDestroyed(family: traits))
	}
}

// MARK: - event handler
extension Family: EventHandler {

	fileprivate final func handleComponentAddedToEntity(event: ComponentAdded) {
		update(membership: event.to)
	}

	fileprivate final func handleComponentUpdatedAtEntity(event: ComponentUpdated) {
		update(membership: event.at)
	}

	fileprivate final func handleComponentRemovedFromEntity(event: ComponentRemoved) {
		update(membership: event.from)
	}

}
*/
