//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

class EmptyComponent: Component {
    static let identifier: ComponentIdentifier = .init(EmptyComponent.self)
}

class Name: Component {
    static let identifier: ComponentIdentifier = .init(Name.self)

    var name: String
    init(name: String) {
        self.name = name
    }
}

class Position: Component {
    static var identifier: ComponentIdentifier = .init(Position.self)

    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

class Velocity: Component {
    static var identifier: ComponentIdentifier = .init(Velocity.self)

    var a: Float
    init(a: Float) {
        self.a = a
    }
}

class Party: Component {
    static var identifier: ComponentIdentifier = .init(Party.self)

    var partying: Bool
    init(partying: Bool) {
        self.partying = partying
    }
}

class Color: Component {
    static var identifier: ComponentIdentifier = .init(Color.self)

    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
}

class ExampleSystem {
    private let family: Family2<Position, Velocity>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: EmptyComponent.self)
    }

    func update(deltaT: Double) {
        family.forEach { (position: Position, velocity: Velocity) in
            position.x *= 2
            velocity.a *= 2
        }
    }
}

final class SingleGameState: SingleComponent {
    static var identifier: ComponentIdentifier = .init(SingleGameState.self)

    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}
