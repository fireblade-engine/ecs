//
//  EntityHub.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public class EntityHub: EventHandler {
	public weak var delegate: EventHub?

	public lazy var eventHub: DefaultEventHub = { return DefaultEventHub() }()

	private(set) var entities: EntityStorage
	private(set) var families: FamilyStorage

	public init() {
		entities = DefaultEntityStorage()

		families = DefaultFamilyStorage()

		self.delegate = eventHub

		subscribe(event: handleEntityCreated)
		subscribe(event: handleEntityDestroyed)

		subscribe(event: handleComponentAdded)
		subscribe(event: handleComponentUpdated)
		subscribe(event: handleComponentRemoved)

		subscribe(event: handleFamilyCreated)
		subscribe(event: handleFamilyMemberAdded)
		subscribe(event: handleFamilyMemberUpdated)
		subscribe(event: handleFamilyMemberRemoved)
		subscribe(event: handleFamilyDestroyed)
	}

	deinit {
		unsubscribe(event: handleEntityCreated)
		unsubscribe(event: handleEntityDestroyed)

		unsubscribe(event: handleComponentAdded)
		unsubscribe(event: handleComponentUpdated)
		unsubscribe(event: handleComponentRemoved)

		unsubscribe(event: handleFamilyCreated)
		unsubscribe(event: handleFamilyMemberUpdated)
		unsubscribe(event: handleFamilyMemberAdded)
		unsubscribe(event: handleFamilyMemberRemoved)
		unsubscribe(event: handleFamilyDestroyed)
	}

}

// MARK: - creator entity
extension EntityHub {

	public func createEntity() -> Entity {
		let newEntity = Entity(uei: UEI.next, dispatcher: eventHub)
		// ^ dispatches entity creation event here ^
		let success: Bool = entities.add(newEntity)
		assert(success == true, "Entity with the exact identifier already exists")

		return newEntity
	}

}

// MARK: - create/get family
extension EntityHub {

	@discardableResult
	public func family(with traits: FamilyTraits) -> (new: Bool, family: Family) {

		if let existingFamily: Family = families[traits] {
			return (new: false, family: existingFamily)
		}

		let newFamily = Family(traits: traits, eventHub: eventHub)
		// ^ dispatches family creation event here ^
		let success = families.add(newFamily)
		assert(success, "Family with the exact traits already exists")

		refreshFamilyCache()

		return (new: true, family: newFamily)
	}

	fileprivate func onFamilyCreated(_ newFamily: Family) {

		newFamily.update(membership: entities.iterator)
	}

	fileprivate func refreshFamilyCache() {
		// TODO: 
	}

}

// MARK: - event handler
extension EntityHub {
	func handleEntityCreated(_ e: EntityCreated) { print(e) }
	func handleEntityDestroyed(_ e: EntityDestroyed) { print(e) }

	func handleComponentAdded(_ e: ComponentAdded) { print(e) }
	func handleComponentUpdated(_ e: ComponentUpdated) { print(e) }
	func handleComponentRemoved(_ e: ComponentRemoved) { print(e) }

	func handleFamilyCreated(_ e: FamilyCreated) {
		print(e)
		let newFamily: Family = e.family
		onFamilyCreated(newFamily)

	}
	func handleFamilyMemberAdded(_ e: FamilyMemberAdded) { print(e) }
	func handleFamilyMemberUpdated(_ e: FamilyMemberUpdated) { print(e) }
	func handleFamilyMemberRemoved(_ e: FamilyMemberRemoved) { print(e) }
	func handleFamilyDestroyed(_ e: FamilyDestroyed) { print(e) }
}
