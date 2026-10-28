import FirebladeECS

public struct MovementSystem {
    private let family: Family<PositionComponent, VelocityComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requiresAll: PositionComponent.self, VelocityComponent.self)
    }

    public func update() {
        family.forEach(reading: VelocityComponent.self, writing: PositionComponent.self) { vel, pos in
            pos.x += vel.x
            pos.y += vel.y
        }
    }
}

public struct DataSystem {
    private let family: Family<DataComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requires: DataComponent.self)
    }

    public func update() {
        family.forEach(writing: DataComponent.self) { data in
            data.a += 1
            data.b += 2
        }
    }
}

public struct MoreComplexSystem {
    private let family: Family<PositionComponent, VelocityComponent, DataComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requiresAll: PositionComponent.self, VelocityComponent.self, DataComponent.self)
    }

    public func update() {
        family.forEach(reading: VelocityComponent.self, DataComponent.self, writing: PositionComponent.self) { vel, data, pos in
            pos.x += vel.x + Float(data.a)
            pos.y += vel.y + Float(data.b)
        }
    }
}

public struct HealthSystem {
    private let family: Family<HealthComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requires: HealthComponent.self)
    }

    public func update() {
        family.forEach(writing: HealthComponent.self) { health in
            if health.hp > health.maxHP {
                health.hp = health.maxHP
            }
        }
    }
}

public struct DamageSystem {
    private let family: Family<HealthComponent, DamageComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requiresAll: HealthComponent.self, DamageComponent.self)
    }

    public func update() {
        family.forEach(reading: DamageComponent.self, writing: HealthComponent.self) { dmg, health in
            health.hp -= dmg.damage
        }
    }
}

public struct SpriteSystem {
    private let family: Family<HealthComponent, SpriteComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requiresAll: HealthComponent.self, SpriteComponent.self)
    }

    public func update() {
        family.forEach(reading: HealthComponent.self, writing: SpriteComponent.self) { health, sprite in
            sprite.character = health.hp > 0 ? 65 : 66
        }
    }
}

public struct RenderSystem {
    private let family: Family<PositionComponent>

    public init(nexus: Nexus) {
        family = nexus.family(requires: PositionComponent.self)
    }

    public func update(accumulator: inout Float) {
        family.forEach(reading: PositionComponent.self) { pos in
            accumulator += pos.x + pos.y
        }
    }
}

public func setUpNexus(storage: Nexus.StorageKind = .archetype, count: Int = 10000) -> Nexus {
    let nexus = Nexus(storage: storage)
    for i in 0 ..< count {
        let type = i % 4
        switch type {
        case 0:
            // Heroes: Pos + Vel + Data + Health + Sprite
            nexus.createEntity(with:
                PositionComponent(x: Float(i), y: Float(i)),
                VelocityComponent(x: 1, y: 1),
                DataComponent(a: Int32(i), b: Int32(i)),
                HealthComponent(hp: 100, maxHP: 100, status: 1),
                SpriteComponent(character: 65)
            )
        case 1:
            // Monsters: Pos + Vel + Health + Damage + Sprite
            nexus.createEntity(with:
                PositionComponent(x: Float(i), y: Float(i)),
                VelocityComponent(x: 1, y: 1),
                HealthComponent(hp: 50, maxHP: 50, status: 1),
                DamageComponent(damage: 10),
                SpriteComponent(character: 77)
            )
        case 2:
            // Props: Pos + Sprite
            nexus.createEntity(with:
                PositionComponent(x: Float(i), y: Float(i)),
                SpriteComponent(character: 80)
            )
        default:
            // Dynamic: Pos + Vel + Data
            nexus.createEntity(with:
                PositionComponent(x: Float(i), y: Float(i)),
                VelocityComponent(x: 1, y: 1),
                DataComponent(a: Int32(i), b: Int32(i))
            )
        }
    }
    return nexus
}
