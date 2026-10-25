//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

struct EmptyComponent: Component, Sendable {}

struct Name: Component, Sendable {
    var name: String
    init(name: String) {
        self.name = name
    }
}

struct Position: Component, Sendable {
    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

struct Velocity: Component, Sendable {
    var a: Float
    init(a: Float) {
        self.a = a
    }
}

struct Party: Component, Sendable {
    var partying: Bool
    init(partying: Bool) {
        self.partying = partying
    }
}

struct Color: Component, Sendable {
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
        // iteration yields copies: writes go through the entity
        for entity in family.entities {
            entity.modify(Position.self) { $0.x *= 2 }
            entity.modify(Velocity.self) { $0.a *= 2 }
        }
    }
}

struct SingleGameState: SingleComponent, Sendable {
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
