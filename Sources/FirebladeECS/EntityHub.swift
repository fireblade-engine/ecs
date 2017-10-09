//
//  EntityHub.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public class EntityHub: EventHandler {
	public weak var delegate: EventHub?

	public lazy var eventHub: DefaultEventHub = { return DefaultEventHub() }()

	private(set) var entites: Set<Entity>
	//private(set) var entites: [UEI:Entity] = [:]
	private(set) var families: Set<Family>

	public init() {
		entites = Set<Entity>()
		entites.reserveCapacity(512)

		families = Set<Family>()
		families.reserveCapacity(64)

		self.delegate = eventHub

		subscribe(event: handleEntityCreated)
		subscribe(event: handleFamilyCreated)
		subscribe(event: handleComponentAdded)
		subscribe(event: handleFamilyMemberAdded)
	}
	deinit {
		unsubscribe(event: handleEntityCreated)
		unsubscribe(event: handleFamilyCreated)
		unsubscribe(event: handleComponentAdded)
		unsubscribe(event: handleFamilyMemberAdded)
	}

}

// MARK: - creators
extension EntityHub {
	public func createEntity() -> Entity {
		let newEntity = Entity(uei: UEI.next, dispatcher: eventHub)
		// ^ dispatches entity creation event here ^
		let (success, _) = entites.insert(newEntity)
		assert(success == true, "Entity with the exact identifier already exists")

		return newEntity
	}

	public func createFamily(with traits: FamilyTraits) -> Family {
		let newFamily = Family(traits: traits, eventHub: eventHub)
		// ^ dispatches family creation event here ^
		let (success, _) = families.insert(newFamily)
		assert(success == true, "Family with the exact traits already exists")

		return newFamily
	}

}

// MARK: - event handler
extension EntityHub {
	func handleEntityCreated(_ e: EntityCreated) { print(e) }
	func handleFamilyCreated(_ e: FamilyCreated) { print(e) }

	func handleComponentAdded(_ e: ComponentAdded) { print(e) }
	func handleFamilyMemberAdded(_ e: FamilyMemberAdded) { print(e) }
}
