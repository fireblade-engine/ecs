//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

struct EmptyComponent: Component { }

struct Name: Component {
	var name: String
}

struct Position: Component {
	var x: Int
	var y: Int
}

struct Velocity: Component {
	var a: Float
}

class DebugEventHandler: EventHandler {

	let eventHub = DefaultEventHub()

	var delegate: EventHub?

	init() {
		delegate = eventHub
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
		print(ec)
	}

	func handleEntityDestroyed(ed: EntityDestroyed) {
		print(ed)
	}

	func handleComponentAdded(ca: ComponentAdded) {
		print(ca)
	}

}
