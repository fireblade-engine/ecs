// Update population ported from ReferenceUpdatePopulation.swift in ECSBenchmark (uniform and mixed hero/monster worlds).
import FirebladeECS

struct CompatPlayerInitialization {
    let position: CompatPositionPayload
    let player: CompatPlayerPayload
    let health: CompatHealthPayload
    let damage: CompatDamagePayload
    let sprite: CompatSpritePayload
}

struct CompatEntityFixture {
    let removesPosition: Bool
    let removesVelocity: Bool
    let removesData: Bool
    let playerInitialization: CompatPlayerInitialization?
}

enum CompatPopulation {
    static func uniform(at index: Int) -> CompatEntityFixture {
        makeFixture(at: index, removesPosition: false, removesVelocity: false, removesData: false, addsPlayer: true, forcedPlayerType: nil)
    }

    static func mixed(at index: Int, entityCount: Int) -> CompatEntityFixture {
        let removalStart = entityCount < 100 ? 0 : 2 * entityCount / 4
        let removalEnd = entityCount < 100 ? entityCount - 1 : 3 * entityCount / 4
        let isInRemovalBand = index >= removalStart && index <= removalEnd
        let removalOrdinal = index - removalStart
        let removesComponents = isInRemovalBand && (entityCount < 100 || removalOrdinal % 10 == 0)
        let playerSelection = mixedPlayerSelection(at: index, entityCount: entityCount)
        return makeFixture(
            at: index,
            removesPosition: removesComponents && index % 7 == 0,
            removesVelocity: removesComponents && index % 11 == 0,
            removesData: removesComponents && index % 13 == 0,
            addsPlayer: playerSelection.addsPlayer,
            forcedPlayerType: playerSelection.forcedType
        )
    }

    static func fixture(at index: Int, entityCount: Int, isMixed: Bool) -> CompatEntityFixture {
        isMixed ? mixed(at: index, entityCount: entityCount) : uniform(at: index)
    }

    static func populate(nexus: Nexus, entityCount: Int, isMixed: Bool) {
        var entities: [Entity] = []
        entities.reserveCapacity(entityCount)

        // The reference creates every base entity and applies its removals before adding any player components.
        for index in 0 ..< entityCount {
            let fixture = fixture(at: index, entityCount: entityCount, isMixed: isMixed)
            let entity = nexus.createEntity(
                with: CompatPosition(CompatPositionPayload()),
                CompatVelocity(CompatVelocityPayload()),
                CompatData(CompatDataPayload())
            )
            if fixture.removesPosition { entity.remove(CompatPosition.self) }
            if fixture.removesVelocity { entity.remove(CompatVelocity.self) }
            if fixture.removesData { entity.remove(CompatData.self) }
            entities.append(entity)
        }

        for index in entities.indices {
            guard let initialization = fixture(at: index, entityCount: entityCount, isMixed: isMixed).playerInitialization else { continue }
            let entity = entities[index]
            entity.set(CompatPlayer(CompatPlayerPayload(rng: CompatXoshiro128(seed: playerSeed(for: index)))))
            entity.set(CompatHealth(CompatHealthPayload()))
            entity.set(CompatDamage(CompatDamagePayload()))
            entity.set(CompatSprite(CompatSpritePayload()))
            if !entity.has(CompatPosition.self) {
                entity.set(CompatPosition(CompatPositionPayload()))
            }
            entity.set(CompatPlayer(initialization.player))
            entity.set(CompatHealth(initialization.health))
            entity.set(CompatDamage(initialization.damage))
            entity.set(CompatSprite(initialization.sprite))
            entity.set(CompatPosition(initialization.position))
        }
    }
}

private extension CompatPopulation {
    static func makeFixture(
        at index: Int,
        removesPosition: Bool,
        removesVelocity: Bool,
        removesData: Bool,
        addsPlayer: Bool,
        forcedPlayerType: CompatPlayerType?
    ) -> CompatEntityFixture {
        CompatEntityFixture(
            removesPosition: removesPosition,
            removesVelocity: removesVelocity,
            removesData: removesData,
            playerInitialization: addsPlayer ? initializePlayer(at: index, forcedType: forcedPlayerType) : nil
        )
    }

    static func mixedPlayerSelection(at index: Int, entityCount: Int) -> (addsPlayer: Bool, forcedType: CompatPlayerType?) {
        let isEligible = entityCount >= 100 || index == 0 || index >= entityCount / 8
        guard isEligible else { return (false, nil) }

        let ordinal: Int
        if entityCount < 100, entityCount / 8 > 0 {
            ordinal = index == 0 ? 0 : index - entityCount / 8 + 1
        } else {
            ordinal = index
        }
        let isSelected = entityCount < 100 && index == 0 || entityCount >= 100 || ordinal % 2 == 0
        guard isSelected else { return (false, nil) }

        if index == 0 { return (true, .hero) }
        if index % 6 == 0 { return (true, nil) }
        if index % 4 == 0 { return (true, .hero) }
        if index % 2 == 0 { return (true, .monster) }
        return (false, nil)
    }

    static func initializePlayer(at index: Int, forcedType: CompatPlayerType?) -> CompatPlayerInitialization {
        var player = CompatPlayerPayload(rng: CompatXoshiro128(seed: playerSeed(for: index)))
        let typeRoll = player.rng.range(1, 100)
        let type = forcedType ?? (typeRoll <= 3 ? .npc : typeRoll <= 30 ? .hero : .monster)
        player.type = type

        var health = CompatHealthPayload()
        var damage = CompatDamagePayload()
        switch type {
        case .hero:
            health.maxhp = Int32(player.rng.range(5, 15))
            damage.def = Int32(player.rng.range(2, 6))
            damage.atk = Int32(player.rng.range(4, 10))
        case .monster:
            health.maxhp = Int32(player.rng.range(4, 12))
            damage.def = Int32(player.rng.range(2, 8))
            damage.atk = Int32(player.rng.range(3, 9))
        case .npc:
            health.maxhp = Int32(player.rng.range(6, 12))
            damage.def = Int32(player.rng.range(3, 8))
            damage.atk = 0
        }

        let x = Float(player.rng.range(0, 420)) - 100
        let y = Float(player.rng.range(0, 340)) - 100
        return CompatPlayerInitialization(
            position: CompatPositionPayload(x: x, y: y),
            player: player,
            health: health,
            damage: damage,
            sprite: CompatSpritePayload(character: 95)
        )
    }

    /// The reference seeds player RNGs from object addresses; ordinal seeds keep this workload reproducible instead.
    static func playerSeed(for index: Int) -> UInt32 {
        0x6D2B_79F5 &+ UInt32(truncatingIfNeeded: index) &* 0x9E37_79B9
    }
}
