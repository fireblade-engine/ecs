//
//  EntityHubTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

import XCTest
@testable import FirebladeECS

class EntityHubTests: XCTestCase {

	let entityHub = EntityHub()

	override func setUp() {
		super.setUp()
		entityHub.eventHub.sniffer = self
	}

	func testCreateEntity() {
		let newEntity: Entity = entityHub.createEntity()

		XCTAssert(newEntity.hasComponents == false)
		//TODO: XCTAssert(entityHub.entites[newEntity.uei] == newEntity)
		//TODO: XCTAssert(entityHub.entites[newEntity.uei] === newEntity)
	}

	func testCreateEntityAndAddComponent() {
		let newEntity: Entity = entityHub.createEntity()

		let emptyComp = EmptyComponent()

		newEntity.add(component: emptyComp)

		XCTAssert(newEntity.hasComponents)
		XCTAssert(newEntity.numComponents == 1)

		//TODO: XCTAssert(entityHub.entites[newEntity.uei] == newEntity)
		//TODO: XCTAssert(entityHub.entites[newEntity.uei] === newEntity)

	}

}

extension EntityHubTests: EventSniffer {
	public func subscriber(subsribed to: UET) {

	}

	public func subscriber(unsubsribed from: UET) {

	}

	public func dispatched<E>(event: E) where E : Event {

	}

}
