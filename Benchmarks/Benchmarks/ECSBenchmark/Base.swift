//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

class EmptyComponent: Component {}

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

class Color: Component {
    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
}

class ExampleSystem {
    private let family: Family<Position, Velocity>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: EmptyComponent.self)
    }

    func update(deltaT _: Double) {
        family.forEach { (position: Position, velocity: Velocity) in
            position.x *= 2
            velocity.a *= 2
        }
    }
}

final class SingleGameState: SingleComponent {
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}

func setUpNexus() -> Nexus {
    let numEntities = 10000
    let nexus = Nexus()

    for i in 0 ..< numEntities {
        nexus.createEntity().assign(Position(x: 1 + i, y: 2 + i),
                                    Name(name: "myName\(i)"),
                                    Velocity(a: 3.14),
                                    EmptyComponent(),
                                    Color())
    }

    precondition(nexus.numEntities == numEntities)
//    precondition(nexus.numFamilies == 1)
    precondition(nexus.numComponents == numEntities * 5)

    return nexus
}
