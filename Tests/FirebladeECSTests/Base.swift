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
    static let identifier: ComponentIdentifier = .init(Position.self)
    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

class Velocity: Component {
    static let identifier: ComponentIdentifier = .init(Velocity.self)
    var a: Float
    init(a: Float) {
        self.a = a
    }
}

class Party: Component {
    static let identifier: ComponentIdentifier = .init(Party.self)
    var partying: Bool
    init(partying: Bool) {
        self.partying = partying
    }
}

class Color: Component {
    static let identifier: ComponentIdentifier = .init(Color.self)
    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
}

class Index: Component {
    static let identifier: ComponentIdentifier = .init(Index.self)
    var index: Int

    init(index: Int) {
        self.index = index
    }
}

final class SingleGameState: SingleComponent {
    static let identifier: ComponentIdentifier = .init(SingleGameState.self)
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
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

class ColorSystem {
    let nexus: Nexus
    lazy var colors = nexus.family(requires: Color.self)

    init(nexus: Nexus) {
        self.nexus = nexus
    }

    func update() {
        colors
            .forEach { (color: Color) in
                color.r = 1
                color.g = 2
                color.b = 3
        }
    }
}

class PositionSystem {
    let positions: Family1<Position>

    var velocity: Double = 4.0

    init(nexus: Nexus) {
        positions = nexus.family(requires: Position.self)
    }

    func randNorm() -> Double {
        return 4.0
    }

    func update() {
        positions
            .forEach { [unowned self](pos: Position) in
                let deltaX: Double = self.velocity * ((self.randNorm() * 2) - 1)
                let deltaY: Double = self.velocity * ((self.randNorm() * 2) - 1)
                let x = pos.x + Int(deltaX)
                let y = pos.y + Int(deltaY)

                pos.x = x
                pos.y = y
        }
    }
}
