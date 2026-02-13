//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

#if FRB_ENABLE_BENCHMARKS
import FirebladeECS

class EmptyComponent: Component, @unchecked Sendable {
}

class Name: Component, @unchecked Sendable {
    var name: String
    init(name: String) {
        self.name = name
    }
}

class Position: Component, @unchecked Sendable {
    var x: Int
    var y: Int
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

class Velocity: Component, @unchecked Sendable {
    var a: Float
    init(a: Float) {
        self.a = a
    }
}

class Party: Component, @unchecked Sendable {
    var partying: Bool
    init(partying: Bool) {
        self.partying = partying
    }
}

class Color: Component, @unchecked Sendable {
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

final class SingleGameState: SingleComponent, @unchecked Sendable {
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}
#endif
