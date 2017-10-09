import XCTest
@testable import FirebladeECS

class FirebladeECSTests: XCTestCase {

	class MyEventHandler: EventHandler {
		init() {
			subscribe(event: handleEntityCreated)
			subscribe(event: handleEntityDestroyed)
			subscribe(event: handleComponentAdded)
		}
		deinit {
			unsubscribe(event: handleEntityCreated)
			unsubscribe(event: handleComponentAdded)
			unsubscribe(event: handleEntityDestroyed)
		}

		func handleEntityCreated(ec: EntityCreated) {
			Log.warn(ec)
		}

		func handleEntityDestroyed(ed: EntityDestroyed) {
			Log.warn(ed)
		}

		func handleComponentAdded(ca: ComponentAdded) {
			Log.debug(ca)
		}

	}

	let eventHandler: MyEventHandler = MyEventHandler()

	func testCreateEntity() {
		let newEntity = Entity()

		XCTAssert(newEntity.hasComponents == false)
		XCTAssert(newEntity.uei == 1)
		XCTAssert(newEntity.numComponents == 0)

		let pC: EmptyComponent? = newEntity.peekComponent()
		XCTAssert(pC == nil)
	}
}
