//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {

	public var nexus: Nexus

	// members of this Family must conform to these traits
	public let traits: FamilyTraits

	public private(set) var members: ContiguousArray<EntityIdentifier>

	public init(_ nexus: Nexus, traits: FamilyTraits) {

		members = ContiguousArray<EntityIdentifier>()
		members.reserveCapacity(64)

		self.traits = traits

		self.nexus = nexus

		/*subscribe(event: handleComponentAddedToEntity)
		subscribe(event: handleComponentUpdatedAtEntity)
		subscribe(event: handleComponentRemovedFromEntity)
*/
		defer {
			//notifyCreated()
		}

	}

	deinit {

		members.removeAll()

		/*unsubscribe(event: handleComponentAddedToEntity)
		unsubscribe(event: handleComponentUpdatedAtEntity)
		unsubscribe(event: handleComponentRemovedFromEntity)*/

		defer {
			// notifyDestroyed()
		}

	}
}

// MARK: - update family membership
extension Family {

	func update(membership entityIds: AnyIterator<EntityIdentifier>) {
		while let entityId: EntityIdentifier = entityIds.next() {
			update(membership: entityId)
		}
	}

	func update(membership entities: AnyIterator<Entity>) {
		while let entity: Entity = entities.next() {
			update(membership: entity)
		}
	}

	fileprivate func update(membership entityId: EntityIdentifier) {
		guard let entity = nexus.get(entity: entityId) else {
			fatalError("no entity with id \(entityId) in \(nexus)")
		}
		update(membership: entity)
	}

	fileprivate func update(membership entity: Entity) {
		let isMatch: Bool = traits.isMatch(entity)
		switch isMatch {
		case true:
			push(entity.identifier)
		case false:
			remove(entity.identifier)
		}
	}

	fileprivate func push(_ entityId: EntityIdentifier) {
		assert(!members.contains(entityId), "entity with id \(entityId) already in family")
		members.append(entityId)
		// TODO: notify(added: entityId)
	}

	fileprivate func remove(_ entityId: EntityIdentifier) {
		guard let index: Int = members.index(of: entityId) else {
			fatalError("removing entity id \(entityId) that is not in family")
		}
		let removed: EntityIdentifier? = members.remove(at: index)
		assert(removed != nil)
		if let removedEntity: EntityIdentifier = removed {
			// TODO: notify(removed: removedEntity)
		}
	}
}

// MARK: - member iterator
extension Family {
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
}

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
