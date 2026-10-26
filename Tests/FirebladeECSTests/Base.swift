//
//  Base.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

import FirebladeECS

struct EmptyComponent: Equatable, Component, Sendable {
}

struct Optionals: Equatable, Component, DefaultInitializable, Sendable {
    var int: Int?
    var float: Float?
    var string: String?

    init() {
        self.init(nil, nil, nil)
    }

    init(_ int: Int?, _ float: Float?, _ string: String?) {
        self.int = int
        self.float = float
        self.string = string
    }
}

struct Name: Equatable, Component, DefaultInitializable, Sendable {
    var name: String
    init(name: String) {
        self.name = name
    }

    init() {
        self.init(name: "")
    }
}
extension Name: Codable { }

struct Comp1: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp2: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp3: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp4: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp5: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp6: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp7: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
struct Comp8: Equatable, Component, Sendable, Codable {
    var value: Int
    init(_ value: Int) { self.value = value }
}

struct Position: Equatable, Component, DefaultInitializable, Sendable {
    var x: Int
    var y: Int

    init() {
        self.init(x: 0, y: 0)
    }

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
extension Position: Codable { }

struct Velocity: Equatable, Component, DefaultInitializable, Sendable {
    var a: Float

    init(a: Float) {
        self.a = a
    }

    init() {
        self.init(a: 0)
    }
}

struct Party: Equatable, Component, Sendable {
    var partying: Bool

    init(partying: Bool) {
        self.partying = partying
    }
}
extension Party: Codable { }

struct Color: Equatable, Component, Sendable {
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

struct Index: Equatable, Component, Sendable {
    var index: Int

    init(index: Int) {
        self.index = index
    }
}

struct MyComponent: Equatable, Component, Codable, Sendable {
    var name: String
    var flag: Bool

    init(name: String, flag: Bool) {
        self.name = name
        self.flag = flag
    }
}

struct YourComponent: Equatable, Component, Sendable {
    var number: Float

    init(number: Float) {
        self.number = number
    }
}
extension YourComponent: Decodable { }
extension YourComponent: Encodable { }

struct SingleGameState: SingleComponent, Equatable {
    var shouldQuit: Bool = false
    var playerHealth: Int = 67
}

class ExampleSystem {
    private let family: Family<Position, Velocity>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: EmptyComponent.self)
    }

    func update(deltaT: Double) {
        // iteration yields copies, writes go through the entity
        for entity in family.entities {
            entity.modify(Position.self) { $0.x *= 2 }
            entity.modify(Velocity.self) { $0.a *= 2 }
        }
    }
}

class ColorSystem {
    let nexus: Nexus
    lazy var colors = nexus.family(requiresAll: Color.self)

    init(nexus: Nexus) {
        self.nexus = nexus
    }

    func update() {
        for entity in colors.entities {
            entity.modify(Color.self) {
                $0.r = 1
                $0.g = 2
                $0.b = 3
            }
        }
    }
}

class PositionSystem {
    let positions: Family<Position>

    var velocity: Double = 4.0

    init(nexus: Nexus) {
        positions = nexus.family(requiresAll: Position.self)
    }

    func randNorm() -> Double {
        4.0
    }

    func update() {
        for (entity, pos) in positions.entityAndComponents {
            let deltaX: Double = velocity * ((randNorm() * 2) - 1)
            let deltaY: Double = velocity * ((randNorm() * 2) - 1)
            entity.set(Position(x: pos.x + Int(deltaX), y: pos.y + Int(deltaY)))
        }
    }
}

/// Test convenience: an integer literal is the index of an identifier of generation 0, the first generation of every slot.
extension EntityIdentifier: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self.init(index: value, generation: 0)
    }
}
