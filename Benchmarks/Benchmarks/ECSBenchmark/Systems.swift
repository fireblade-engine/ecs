import FirebladeECS
import FirebladeECSV1

// MARK: - V1 Systems (FirebladeECSV1.Nexus)

public final class V1MovementSystem {
    private let family: FirebladeECSV1.Family<V1PositionComponent, V1VelocityComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requiresAll: V1PositionComponent.self, V1VelocityComponent.self)
    }

    public func update() {
        family.forEach { pos, vel in
            pos.x += vel.x
            pos.y += vel.y
        }
    }
}

public final class V1DataSystem {
    private let family: FirebladeECSV1.Family<V1DataComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requires: V1DataComponent.self)
    }

    public func update() {
        family.forEach { data in
            data.a += 1
            data.b += 2
        }
    }
}

public final class V1MoreComplexSystem {
    private let family: FirebladeECSV1.Family<V1PositionComponent, V1VelocityComponent, V1DataComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requiresAll: V1PositionComponent.self, V1VelocityComponent.self, V1DataComponent.self)
    }

    public func update() {
        family.forEach { pos, vel, data in
            pos.x += vel.x + Float(data.a)
            pos.y += vel.y + Float(data.b)
        }
    }
}

public final class V1HealthSystem {
    private let family: FirebladeECSV1.Family<V1HealthComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requires: V1HealthComponent.self)
    }

    public func update() {
        family.forEach { health in
            if health.hp > health.maxHP {
                health.hp = health.maxHP
            }
        }
    }
}

public final class V1DamageSystem {
    private let family: FirebladeECSV1.Family<V1HealthComponent, V1DamageComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requiresAll: V1HealthComponent.self, V1DamageComponent.self)
    }

    public func update() {
        family.forEach { health, dmg in
            health.hp -= dmg.damage
        }
    }
}

public final class V1SpriteSystem {
    private let family: FirebladeECSV1.Family<V1HealthComponent, V1SpriteComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requiresAll: V1HealthComponent.self, V1SpriteComponent.self)
    }

    public func update() {
        family.forEach { health, sprite in
            sprite.character = health.hp > 0 ? 65 : 66
        }
    }
}

public final class V1RenderSystem {
    private let family: FirebladeECSV1.Family<V1PositionComponent>

    public init(nexus: FirebladeECSV1.Nexus) {
        family = nexus.family(requires: V1PositionComponent.self)
    }

    public func update(accumulator: inout Float) {
        family.forEach { pos in
            accumulator += pos.x + pos.y
        }
    }
}

// MARK: - V2 Systems (FirebladeECS.Nexus)

public struct V2MovementSystem {
    private let family: FirebladeECS.Family<V2PositionComponent, V2VelocityComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requiresAll: V2PositionComponent.self, V2VelocityComponent.self)
    }

    public func update() {
        family.forEach(reading: V2VelocityComponent.self, writing: V2PositionComponent.self) { vel, pos in
            pos.x += vel.x
            pos.y += vel.y
        }
    }
}

public struct V2DataSystem {
    private let family: FirebladeECS.Family<V2DataComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requires: V2DataComponent.self)
    }

    public func update() {
        family.forEach(writing: V2DataComponent.self) { data in
            data.a += 1
            data.b += 2
        }
    }
}

public struct V2MoreComplexSystem {
    private let family: FirebladeECS.Family<V2PositionComponent, V2VelocityComponent, V2DataComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requiresAll: V2PositionComponent.self, V2VelocityComponent.self, V2DataComponent.self)
    }

    public func update() {
        family.forEach(reading: V2VelocityComponent.self, V2DataComponent.self, writing: V2PositionComponent.self) { vel, data, pos in
            pos.x += vel.x + Float(data.a)
            pos.y += vel.y + Float(data.b)
        }
    }
}

public struct V2HealthSystem {
    private let family: FirebladeECS.Family<V2HealthComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requires: V2HealthComponent.self)
    }

    public func update() {
        family.forEach(writing: V2HealthComponent.self) { health in
            if health.hp > health.maxHP {
                health.hp = health.maxHP
            }
        }
    }
}

public struct V2DamageSystem {
    private let family: FirebladeECS.Family<V2HealthComponent, V2DamageComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requiresAll: V2HealthComponent.self, V2DamageComponent.self)
    }

    public func update() {
        family.forEach(reading: V2DamageComponent.self, writing: V2HealthComponent.self) { dmg, health in
            health.hp -= dmg.damage
        }
    }
}

public struct V2SpriteSystem {
    private let family: FirebladeECS.Family<V2HealthComponent, V2SpriteComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requiresAll: V2HealthComponent.self, V2SpriteComponent.self)
    }

    public func update() {
        family.forEach(reading: V2HealthComponent.self, writing: V2SpriteComponent.self) { health, sprite in
            sprite.character = health.hp > 0 ? 65 : 66
        }
    }
}

public struct V2RenderSystem {
    private let family: FirebladeECS.Family<V2PositionComponent>

    public init(nexus: FirebladeECS.Nexus) {
        family = nexus.family(requires: V2PositionComponent.self)
    }

    public func update(accumulator: inout Float) {
        family.forEach(reading: V2PositionComponent.self) { pos in
            accumulator += pos.x + pos.y
        }
    }
}

// MARK: - World Setup / Entity Generator

public func setUpV1Nexus(count: Int = 10000) -> FirebladeECSV1.Nexus {
    let nexus = FirebladeECSV1.Nexus()
    for i in 0 ..< count {
        let type = i % 4
        switch type {
        case 0:
            // Heroes: Pos + Vel + Data + Health + Sprite
            nexus.createEntity(with:
                V1PositionComponent(x: Float(i), y: Float(i)),
                V1VelocityComponent(x: 1, y: 1),
                V1DataComponent(a: Int32(i), b: Int32(i)),
                V1HealthComponent(hp: 100, maxHP: 100, status: 1),
                V1SpriteComponent(character: 65)
            )
        case 1:
            // Monsters: Pos + Vel + Health + Damage + Sprite
            nexus.createEntity(with:
                V1PositionComponent(x: Float(i), y: Float(i)),
                V1VelocityComponent(x: 1, y: 1),
                V1HealthComponent(hp: 50, maxHP: 50, status: 1),
                V1DamageComponent(damage: 10),
                V1SpriteComponent(character: 77)
            )
        case 2:
            // Props: Pos + Sprite
            nexus.createEntity(with:
                V1PositionComponent(x: Float(i), y: Float(i)),
                V1SpriteComponent(character: 80)
            )
        default:
            // Dynamic: Pos + Vel + Data
            nexus.createEntity(with:
                V1PositionComponent(x: Float(i), y: Float(i)),
                V1VelocityComponent(x: 1, y: 1),
                V1DataComponent(a: Int32(i), b: Int32(i))
            )
        }
    }
    return nexus
}

public func setUpV2Nexus(storage: FirebladeECS.Nexus.StorageKind = .archetype, count: Int = 10000) -> FirebladeECS.Nexus {
    let nexus = FirebladeECS.Nexus(storage: storage)
    for i in 0 ..< count {
        let type = i % 4
        switch type {
        case 0:
            // Heroes: Pos + Vel + Data + Health + Sprite
            nexus.createEntity(with:
                V2PositionComponent(x: Float(i), y: Float(i)),
                V2VelocityComponent(x: 1, y: 1),
                V2DataComponent(a: Int32(i), b: Int32(i)),
                V2HealthComponent(hp: 100, maxHP: 100, status: 1),
                V2SpriteComponent(character: 65)
            )
        case 1:
            // Monsters: Pos + Vel + Health + Damage + Sprite
            nexus.createEntity(with:
                V2PositionComponent(x: Float(i), y: Float(i)),
                V2VelocityComponent(x: 1, y: 1),
                V2HealthComponent(hp: 50, maxHP: 50, status: 1),
                V2DamageComponent(damage: 10),
                V2SpriteComponent(character: 77)
            )
        case 2:
            // Props: Pos + Sprite
            nexus.createEntity(with:
                V2PositionComponent(x: Float(i), y: Float(i)),
                V2SpriteComponent(character: 80)
            )
        default:
            // Dynamic: Pos + Vel + Data
            nexus.createEntity(with:
                V2PositionComponent(x: Float(i), y: Float(i)),
                V2VelocityComponent(x: 1, y: 1),
                V2DataComponent(a: Int32(i), b: Int32(i))
            )
        }
    }
    return nexus
}
