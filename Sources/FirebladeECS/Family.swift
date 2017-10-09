//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {

	public var delegate: EventHub?
	fileprivate var dispatcher: EventDispatcher

	// members of this Family must conform to these traits
	public let traits: FamilyTraits

	public private(set) var members: Set<Entity>

	public init(traits: FamilyTraits, eventHub: EventHub & EventDispatcher) {

		members = Set<Entity>()
		members.reserveCapacity(64)

		self.traits = traits

		delegate = eventHub
		dispatcher = eventHub

		subscribe(event: handleComponentAddedToEntity)
		subscribe(event: handleComponentUpdatedAtEntity)
		subscribe(event: handleComponentRemovedFromEntity)

		defer {
			notifyCreated()
		}

	}

	deinit {

		members.removeAll()

		unsubscribe(event: handleComponentAddedToEntity)
		unsubscribe(event: handleComponentUpdatedAtEntity)
		unsubscribe(event: handleComponentRemovedFromEntity)

		defer {
			notifyDestroyed()
		}

	}
}

// MARK: - update family membership
extension Family {

	func update<C: Collection>(membership entites: C) where C.Iterator.Element == Entity {
		var entityIterator = entites.makeIterator()
		while let entity: Entity = entityIterator.next() {
			update(membership: entity)
		}
	}

	fileprivate func update(membership entity: Entity) {
		let isMatch: Bool = traits.isMatch(entity)
		switch isMatch {
		case true:
			push(entity)
		case false:
			remove(entity)
		}
	}

	fileprivate func push(_ entity: Entity) {
		let (added, member) = members.insert(entity)
		switch added {
		case true:
			notify(added: member)
		case false:
			notify(update: entity, previous: member)
		}
	}

	fileprivate func remove(_ entity: Entity) {
		let removed: Entity? = members.remove(entity)
		assert(removed != nil)
		if let removedEntity: Entity = removed {
			notify(removed: removedEntity)
		}
	}
}

// MARK: - entity accessors
extension Family {
	public func entities(_ apply: (Entity) -> Void ) {
		members.lazy.forEach(apply)
	}

	public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Entity) throws -> Result) rethrows -> Result {
		return try members.lazy.reduce(initialResult, nextPartialResult)
	}
}

// MARK: - component accessors
extension Family {
	public func component<A: Component>(_ apply: (A) -> Void) {
		members.lazy.forEach { $0.component(apply) }
	}
	public func components<A: Component, B: Component>(_ apply: (A, B) -> Void) {
		members.lazy.forEach { $0.components(apply) }
	}
	public func components<A: Component, B: Component, C: Component>(_ apply: (A, B, C) -> Void) {
		members.lazy.forEach { $0.components(apply) }
	}
	public func components<A: Component, B: Component, C: Component, D: Component>(_ apply: (A, B, C, D) -> Void) {
		members.lazy.forEach { $0.components(apply) }
	}
	public func components<A: Component, B: Component, C: Component, D: Component, E: Component>(_ apply: (A, B, C, D, E) -> Void) {
		members.lazy.forEach { $0.components(apply) }
	}
	public func components<A: Component, B: Component, C: Component, D: Component, E: Component, F: Component>(_ apply: (A, B, C, D, E, F) -> Void) {
		members.lazy.forEach { $0.components(apply) }
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

// MARK: - event dispatcher
extension Family: EventDispatcher {
	public func dispatch<E>(_ event: E) where E : Event {
		dispatcher.dispatch(event)
	}

	fileprivate func unowned(closure: @escaping (Family) -> Void) {
		let unownedClosure = { [unowned self] in
			closure(self)
		}
		unownedClosure()
	}

	fileprivate func notifyCreated() {
		unowned {
			$0.dispatch(FamilyCreated(family: $0))
		}
	}

	fileprivate func notify(added newEntity: Entity) {
		unowned { [unowned newEntity] in
			$0.dispatch(FamilyMemberAdded(member: newEntity, to: $0))
		}
	}

	fileprivate func notify(update newEntity: Entity, previous oldEntity: Entity) {
		unowned { [unowned newEntity, unowned oldEntity] in
			$0.dispatch(FamilyMemberUpdated(newMember: newEntity, oldMember: oldEntity, in: $0) )
		}
	}

	fileprivate func notify(removed removedEntity: Entity) {
		unowned { [unowned removedEntity] in
			$0.dispatch(FamilyMemberRemoved(member: removedEntity, from: $0))
		}
	}

	fileprivate func notifyDestroyed() {
		//dispatch(event: FamilyDestroyed())
		// dispatch(FamilyDestroyed(family: self))
	}
}

// MARK: - event handler
extension Family: EventHandler {

	fileprivate final func handleComponentAddedToEntity(event: ComponentAdded) {
		unowned let entity: Entity = event.to
		update(membership: entity)
	}

	fileprivate final func handleComponentUpdatedAtEntity(event: ComponentUpdated) {
		unowned let entity: Entity = event.at
		update(membership: entity)
	}

	fileprivate final func handleComponentRemovedFromEntity(event: ComponentRemoved) {
		unowned let entity: Entity = event.from
		update(membership: entity)
	}

}
