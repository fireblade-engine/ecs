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
		//let newComponent: Component = event.component
		let entity: Entity = event.to
		update(membership: entity)
	}

	fileprivate final func handleComponentUpdatedAtEntity(event: ComponentUpdated) {
		//let newComponent: Component = event.component
		//let oldComponent: Component = event.previous
		let entity: Entity = event.at
		update(membership: entity)
	}

	fileprivate final func handleComponentRemovedFromEntity(event: ComponentRemoved) {
		//let removedComponent: Component = event.component
		let entity: Entity = event.from
		update(membership: entity)
	}

}
