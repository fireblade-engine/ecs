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
	var partying: Bool
	init(partying: Bool) {
		self.partying = partying
	}
}

class ExampleSystem {
	private let family: Family

	init(nexus: Nexus) {
		family = nexus.family(requiresAll: [Position.self, Velocity.self], excludesAll: [EmptyComponent.self])
	}

	func update(deltaT: Double) {
		family.iterate(components: Position.self, Velocity.self, Name.self) { (_, positionGetter, velocityGetter, nameGetter) in

			let position: Position = positionGetter!
			let velocity: Velocity = velocityGetter!
			let name: Name? = nameGetter

			position.x *= 2
			velocity.a *= 2

		}
	}

}
