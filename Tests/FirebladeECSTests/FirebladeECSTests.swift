import XCTest
@testable import FirebladeECS

class FirebladeECSTests: XCTestCase {


	func testCreateEntity() {
		let newEntity = Entity()
		XCTAssert(newEntity.hasComponents == false)
		XCTAssert(newEntity.uei == 1)
	}
}
