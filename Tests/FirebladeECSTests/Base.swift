//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

class EmptyComponent: Component, @unchecked Sendable {
}

final class Optionals: Component, DefaultInitializable, @unchecked Sendable {
    var int: Int?
    var float: Float?
    var string: String?

    convenience init() {
        self.init(nil, nil, nil)
    }

    init(_ int: Int?, _ float: Float?, _ string: String?) {
        self.int = int
        self.float = float
        self.string = string
    }
}
extension Optionals: Equatable {
    static func == (lhs: Optionals, rhs: Optionals) -> Bool {
        lhs.int == rhs.int &&
            lhs.float == rhs.float &&
            lhs.string == rhs.string
    }
}

final class Name: Component, DefaultInitializable, @unchecked Sendable {
    var name: String
    init(name: String) {
        self.name = name
    }

    convenience init() {
        self.init(name: "")
    }
}

final class Position: Component, DefaultInitializable, @unchecked Sendable {
    var x: Int
    var y: Int

    convenience init() {
        self.init(x: 0, y: 0)
    }

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
extension Position: Codable { }

final class Velocity: Component, DefaultInitializable, @unchecked Sendable {
    var a: Float

    init(a: Float) {
        self.a = a
    }

    convenience init() {
        self.init(a: 0)
    }
}

final class Party: Component, @unchecked Sendable {
    var partying: Bool

    init(partying: Bool) {
        self.partying = partying
    }
}
extension Party: Codable { }

final class Color: Component, @unchecked Sendable {
    var r: UInt8
    var g: UInt8
    var b: UInt8

    init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.r = r
        self.g = g
        self.b = b
    }
}
extension Color: Codable { }

class Index: Component, @unchecked Sendable {
    var index: Int

    init(index: Int) {
        self.index = index
    }
}

final class MyComponent: Component, @unchecked Sendable {
    var name: String
    var flag: Bool

    init(name: String, flag: Bool) {
        self.name = name
        self.flag = flag
    }
}
extension MyComponent: Decodable { }
extension MyComponent: Encodable { }

final class YourComponent: Component, @unchecked Sendable {
    var number: Float

    init(number: Float) {
        self.number = number
    }
}
extension YourComponent: Decodable { }
extension YourComponent: Encodable { }

final class SingleGameState: SingleComponent, @unchecked Sendable {
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
        4.0
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
