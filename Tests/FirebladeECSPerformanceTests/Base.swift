//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

#if FRB_ENABLE_BENCHMARKS
import FirebladeECS

struct EmptyComponent: Component, Sendable {
}

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

    func update(deltaT: Double) {
        family.forEach { (position: Position, velocity: Velocity) in
            position.x *= 2
            velocity.a *= 2
        }
    }
}

struct SingleGameState: SingleComponent, Sendable {
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}
#endif
