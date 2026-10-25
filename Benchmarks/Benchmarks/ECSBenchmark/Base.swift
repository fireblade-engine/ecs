//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

final class EmptyComponent: Component, @unchecked Sendable {}

final class Name: Component, @unchecked Sendable {
    var name: String
    init(name: String) {
        self.name = name
    }
}

final class Position: Component, @unchecked Sendable {
    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

final class Velocity: Component, @unchecked Sendable {
    var a: Float
    init(a: Float) {
        self.a = a
    }
}

final class Party: Component, @unchecked Sendable {
    var partying: Bool
    init(partying: Bool) {
        self.partying = partying
    }
}

final class Color: Component, @unchecked Sendable {
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
        for (position, velocity) in family {
            position.x *= 2
            velocity.a *= 2
        }
    }
}

final class SingleGameState: SingleComponent, @unchecked Sendable {
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}

func setUpNexus() -> Nexus {
    let numEntities = 10000
    let nexus = Nexus()

    for i in 0 ..< numEntities {
        nexus.createEntity().set(Position(x: 1 + i, y: 2 + i),
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
