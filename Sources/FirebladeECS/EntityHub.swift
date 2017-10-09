//
//  EntityHub.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

class EntityHub: EventHandler {
	weak var delegate: EventHub?
	lazy var eventCenter: DefaultEventHub = { return DefaultEventHub() }()

	private(set) var entites: [UEI:Entity] = [:]

	init() {
		self.delegate = eventCenter

		subscribe(event: handleEntityCreated)
		subscribe(event: handleComponentAdded)
	}
	deinit {
		unsubscribe(event: handleEntityCreated)
		unsubscribe(event: handleComponentAdded)
	}

	func createEntity() -> Entity {
		let newEntity = Entity(uei: UEI.next, dispatcher: eventCenter)
		// ^ dispatches entity creation event here ^
		let prevEntity: Entity? = entites.updateValue(newEntity, forKey: newEntity.uei)
		assert(prevEntity == nil)

		return newEntity
	}

}

// MARK: - event handler
extension EntityHub {
	func handleEntityCreated(_ ec: EntityCreated) {
		print(ec)
	}

	func handleComponentAdded(_ ca: ComponentAdded) {
		print(ca)
	}
}
