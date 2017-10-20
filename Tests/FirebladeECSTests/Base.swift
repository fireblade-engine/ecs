//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

class EmptyComponent: Component { }

class Name: Component {
	var name: String
	init(name: String) {
		self.name = name
	}
}

class Position: Component {
	var x: Int
	var y: Int
	init(x: Int, y: Int) {
		self.x = x
		self.y = y
	}
}

class Velocity: Component {
	var a: Float
	init(a: Float) {
		self.a = a
	}
}

class Party: Component {

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
