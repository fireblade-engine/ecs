import FirebladeECS

public struct PositionComponent: Component, Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct VelocityComponent: Component, Sendable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct DataComponent: Component, Sendable {
    public var a: Int32
    public var b: Int32

    public init(a: Int32, b: Int32) {
        self.a = a
        self.b = b
    }
}

public struct HealthComponent: Component, Sendable {
    public var hp: Int32
    public var maxHP: Int32
    public var status: Int32

    public init(hp: Int32, maxHP: Int32, status: Int32) {
        self.hp = hp
        self.maxHP = maxHP
        self.status = status
    }
}

public struct DamageComponent: Component, Sendable {
    public var damage: Int32

    public init(damage: Int32) {
        self.damage = damage
    }
}

public struct SpriteComponent: Component, Sendable {
    public var character: UInt8

    public init(character: UInt8) {
        self.character = character
    }
}
