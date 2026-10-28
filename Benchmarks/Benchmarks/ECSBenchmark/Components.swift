import FirebladeECS
import FirebladeECSV1

// MARK: - V1 Components (Classes conforming to FirebladeECSV1.Component)

public final class V1PositionComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public final class V1VelocityComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public final class V1DataComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var a: Int32
    public var b: Int32

    public init(a: Int32, b: Int32) {
        self.a = a
        self.b = b
    }
}

public final class V1HealthComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var hp: Int32
    public var maxHP: Int32
    public var status: Int32

    public init(hp: Int32, maxHP: Int32, status: Int32) {
        self.hp = hp
        self.maxHP = maxHP
        self.status = status
    }
}

public final class V1DamageComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var damage: Int32

    public init(damage: Int32) {
        self.damage = damage
    }
}

public final class V1SpriteComponent: FirebladeECSV1.Component, @unchecked Sendable {
    public var character: UInt8

    public init(character: UInt8) {
        self.character = character
    }
}

// MARK: - V2 Components (Structs conforming to FirebladeECS.Component, Sendable)

public struct V2PositionComponent: FirebladeECS.Component, Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct V2VelocityComponent: FirebladeECS.Component, Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct V2DataComponent: FirebladeECS.Component, Sendable {
    public var a: Int32
    public var b: Int32

    public init(a: Int32, b: Int32) {
        self.a = a
        self.b = b
    }
}

public struct V2HealthComponent: FirebladeECS.Component, Sendable {
    public var hp: Int32
    public var maxHP: Int32
    public var status: Int32

    public init(hp: Int32, maxHP: Int32, status: Int32) {
        self.hp = hp
        self.maxHP = maxHP
        self.status = status
    }
}

public struct V2DamageComponent: FirebladeECS.Component, Sendable {
    public var damage: Int32

    public init(damage: Int32) {
        self.damage = damage
    }
}

public struct V2SpriteComponent: FirebladeECS.Component, Sendable {
    public var character: UInt8

    public init(character: UInt8) {
        self.character = character
    }
}
