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
