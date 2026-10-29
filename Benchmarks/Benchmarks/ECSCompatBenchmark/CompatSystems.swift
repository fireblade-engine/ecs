// Payloads, systems and worlds of the update and event workloads. The system set, order and formulas follow
// abeimler/ecs_benchmark at 98678f746e0e2f04c37a3332453c8d98daa94f92 (src/base/base/systems/*.h, Application::init with
// UseMoreComplexSystems): Movement, Data, MoreComplex, Health, Damage, Sprite, Render.
// Everything here compiles unchanged against every revision; component access goes through `CompatSuite.modify`.
import Benchmark
import FirebladeECS

struct CompatXoshiro128: Sendable {
    private(set) var state: (UInt32, UInt32, UInt32, UInt32)

    init(seed: UInt32) {
        state = (seed &+ 3, seed &+ 5, seed &+ 7, seed &+ 11)
    }

    mutating func next() -> UInt32 {
        var s0 = state.0
        var s1 = state.1
        var s2 = state.2
        var s3 = state.3
        let result = Self.rotateLeft(s1 &* 5, by: 7) &* 9
        let t = s1 << 9
        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3
        s2 ^= t
        s3 = Self.rotateLeft(s3, by: 11)
        state = (s0, s1, s2, s3)
        return result
    }

    mutating func range(_ lowerBound: UInt32, _ upperBound: UInt32) -> UInt32 {
        next() % (upperBound &- lowerBound &+ 1) &+ lowerBound
    }

    private static func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
        (value << amount) | (value >> (32 &- amount))
    }
}

struct CompatPositionPayload: Sendable { var x: Float = 0, y: Float = 0 }
struct CompatVelocityPayload: Sendable { var x: Float = 1, y: Float = 1 }
struct CompatDataPayload: Sendable {
    var thingy: Int32 = 0
    var dingy: Double = 0
    var mingy = false
    var numgy: UInt32
    var rng: CompatXoshiro128

    init(seed: UInt32 = 340_383) {
        var rng = CompatXoshiro128(seed: seed)
        numgy = rng.next()
        self.rng = rng
    }
}

/// Declaration order matches upstream (`NPC, Monster, Hero`).
enum CompatPlayerType: Int32, Sendable { case npc = 0, monster = 1, hero = 2 }

struct CompatPlayerPayload: Sendable {
    var rng: CompatXoshiro128
    var type: CompatPlayerType = .npc
}

enum CompatStatusEffect: Int32, Sendable { case spawn = 0, dead = 1, alive = 2 }

struct CompatHealthPayload: Sendable {
    var hp: Int32 = 0
    var maxhp: Int32 = 0
    var status: CompatStatusEffect = .spawn
}
struct CompatDamagePayload: Sendable { var atk: Int32 = 0, def: Int32 = 0 }
struct CompatSpritePayload: Sendable { var character: UInt8 = 32 }
/// Empty marker used by the component-event workloads.
struct CompatMarkerPayload: Sendable {}

typealias CompatPosition = CompatBox<CompatPositionPayload>
typealias CompatVelocity = CompatBox<CompatVelocityPayload>
typealias CompatData = CompatBox<CompatDataPayload>
typealias CompatPlayer = CompatBox<CompatPlayerPayload>
typealias CompatHealth = CompatBox<CompatHealthPayload>
typealias CompatDamage = CompatBox<CompatDamagePayload>
typealias CompatSprite = CompatBox<CompatSpritePayload>
typealias CompatMarker = CompatBox<CompatMarkerPayload>

// MARK: - Systems (each returns the number of members it visited)

struct CompatMovementSystem {
    let family: Family<CompatVelocity, CompatPosition>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatVelocity.self, CompatPosition.self)
    }

    func update(deltaTime: Float) -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write1(family) { velocity, position in
            position.payload.x += velocity.payload.x * deltaTime
            position.payload.y += velocity.payload.y * deltaTime
            visited += 1
        }
        return visited
    }
}

struct CompatDataSystem {
    let family: Family<CompatData>

    init(nexus: Nexus) {
        family = nexus.family(requires: CompatData.self)
    }

    func update(deltaTime: Float) -> Int {
        var visited = 0
        CompatSuite.forEachWriting(family) { data in
            data.payload.thingy = (data.payload.thingy + 1) % 1_000_000
            data.payload.dingy += 0.0001 * Double(deltaTime)
            data.payload.mingy.toggle()
            data.payload.numgy = data.payload.rng.next()
            visited += 1
        }
        return visited
    }
}

/// Upstream `MoreComplexSystem`: reads Position, rewrites Velocity and Data (the data RNG) every tenth `thingy`.
struct CompatMoreComplexSystem {
    let family: Family<CompatPosition, CompatVelocity, CompatData>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatPosition.self, CompatVelocity.self, CompatData.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write2(family) { position, velocity, data in
            if data.payload.thingy % 10 == 0 {
                if position.payload.x > position.payload.y {
                    velocity.payload.x = Float(data.payload.rng.range(3, 19)) - 10
                    velocity.payload.y = Float(data.payload.rng.range(0, 5))
                } else {
                    velocity.payload.x = Float(data.payload.rng.range(0, 5))
                    velocity.payload.y = Float(data.payload.rng.range(3, 19)) - 10
                }
            }
            visited += 1
        }
        return visited
    }
}

/// Upstream `HealthSystem` state machine.
struct CompatHealthSystem {
    let family: Family<CompatHealth>

    init(nexus: Nexus) {
        family = nexus.family(requires: CompatHealth.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachWriting(family) { health in
            if health.payload.hp <= 0, health.payload.status != .dead {
                health.payload.hp = 0
                health.payload.status = .dead
            } else if health.payload.status == .dead, health.payload.hp == 0 {
                health.payload.hp = health.payload.maxhp
                health.payload.status = .spawn
            } else if health.payload.hp >= health.payload.maxhp, health.payload.status != .alive {
                health.payload.hp = health.payload.maxhp
                health.payload.status = .alive
            } else {
                health.payload.status = .alive
            }
            visited += 1
        }
        return visited
    }
}

/// Upstream `DamageSystem`: `atk - def` damage while alive, never below zero hp.
struct CompatDamageSystem {
    let family: Family<CompatDamage, CompatHealth>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatDamage.self, CompatHealth.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write1(family) { damage, health in
            let totalDamage = damage.payload.atk - damage.payload.def
            if health.payload.hp > 0, totalDamage > 0 {
                health.payload.hp = max(health.payload.hp - totalDamage, 0)
            }
            visited += 1
        }
        return visited
    }
}

/// Upstream `SpriteSystem`: '@' hero, 'k' monster, 'h' NPC while alive, '|' dead, '_' spawning.
struct CompatSpriteSystem {
    static let hero = UInt8(ascii: "@")
    static let monster = UInt8(ascii: "k")
    static let npc = UInt8(ascii: "h")
    static let grave = UInt8(ascii: "|")
    static let spawn = UInt8(ascii: "_")

    let family: Family<CompatPlayer, CompatHealth, CompatSprite>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatPlayer.self, CompatHealth.self, CompatSprite.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachRead2Write1(family) { player, health, sprite in
            switch health.payload.status {
            case .alive:
                switch player.payload.type {
                case .hero: sprite.payload.character = Self.hero
                case .monster: sprite.payload.character = Self.monster
                case .npc: sprite.payload.character = Self.npc
                }
            case .dead: sprite.payload.character = Self.grave
            case .spawn: sprite.payload.character = Self.spawn
            }
            visited += 1
        }
        return visited
    }
}

/// Upstream 320x240 frame buffer; `draw` ignores out-of-bounds cells.
final class CompatFrameBuffer {
    static let width = 320
    static let height = 240
    private(set) var cells = [UInt8](repeating: 0, count: width * height)
    /// In-bounds draws since creation.
    private(set) var drawn = 0

    func draw(x: Int, y: Int, _ character: UInt8) {
        guard y >= 0, y < Self.height, x >= 0, x < Self.width else { return }
        cells[x + y * Self.width] = character
        drawn += 1
    }
}

/// Upstream `RenderSystem`: draws every Position+Sprite member into the frame buffer.
struct CompatRenderSystem {
    let family: Family<CompatPosition, CompatSprite>
    let frameBuffer = CompatFrameBuffer()

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatPosition.self, CompatSprite.self)
    }

    func update() -> Int {
        var visited = 0
        let frameBuffer = frameBuffer
        CompatSuite.forEachReading(family) { position, sprite in
            frameBuffer.draw(x: Int(position.payload.x), y: Int(position.payload.y), sprite.payload.character)
            visited += 1
        }
        return visited
    }
}

// MARK: - Worlds

/// A persistent world for one workload: state carries over between passes, as upstream (no reset).
protocol CompatPassRunner: AnyObject {
    /// One timed pass; `operations` is the total number of members visited or changed.
    func pass() -> CompatOutcome
}

/// Two-system (movement, data) or seven-system application over the reference update population.
final class CompatUpdateWorld: CompatPassRunner {
    static let deltaTime: Float = 1.0 / 60.0

    let isComplex: Bool
    let movement: CompatMovementSystem
    let data: CompatDataSystem
    // Only the complex application creates these families; extra families would slow every component mutation.
    let moreComplex: CompatMoreComplexSystem?
    let health: CompatHealthSystem?
    let damage: CompatDamageSystem?
    let sprite: CompatSpriteSystem?
    let render: CompatRenderSystem?

    init(nexus: Nexus, isComplex: Bool) {
        self.isComplex = isComplex
        movement = CompatMovementSystem(nexus: nexus)
        data = CompatDataSystem(nexus: nexus)
        moreComplex = isComplex ? CompatMoreComplexSystem(nexus: nexus) : nil
        health = isComplex ? CompatHealthSystem(nexus: nexus) : nil
        damage = isComplex ? CompatDamageSystem(nexus: nexus) : nil
        sprite = isComplex ? CompatSpriteSystem(nexus: nexus) : nil
        render = isComplex ? CompatRenderSystem(nexus: nexus) : nil
    }

    /// Members visited per system, in execution order.
    func update() -> [Int] {
        let dt = Self.deltaTime
        var visits = [movement.update(deltaTime: dt), data.update(deltaTime: dt)]
        if isComplex, let moreComplex, let health, let damage, let sprite, let render {
            visits.append(moreComplex.update())
            visits.append(health.update())
            visits.append(damage.update())
            visits.append(sprite.update())
            visits.append(render.update())
        }
        return visits
    }

    func pass() -> CompatOutcome {
        CompatOutcome(operations: update().reduce(0, +))
    }
}

/// Component-event workloads: per-entity marker churn, optionally with the Position+Velocity update.
final class CompatEventWorld: CompatPassRunner {
    let withUpdate: Bool
    let movement: CompatMovementSystem
    let markerFamily: Family<CompatMarker>
    let eventView: Family<CompatPosition, CompatVelocity, CompatMarker>
    private var scratch: [Entity] = []

    init(nexus: Nexus, withUpdate: Bool) {
        self.withUpdate = withUpdate
        movement = CompatMovementSystem(nexus: nexus)
        markerFamily = nexus.family(requires: CompatMarker.self)
        eventView = nexus.family(requiresAll: CompatPosition.self, CompatVelocity.self, CompatMarker.self)
        scratch.reserveCapacity(movement.family.count)
    }

    /// Adds a marker to every Position+Velocity match; returns the number added.
    func publishMarkers() -> Int {
        scratch.removeAll(keepingCapacity: true)
        for entity in movement.family.entities {
            scratch.append(entity)
        }
        for entity in scratch {
            entity.set(CompatMarker(CompatMarkerPayload()))
        }
        return scratch.count
    }

    /// Removes the marker from every marked entity, one by one (no type-wide clear exists); returns the number removed.
    func clearMarkers() -> Int {
        scratch.removeAll(keepingCapacity: true)
        for entity in markerFamily.entities {
            scratch.append(entity)
        }
        for entity in scratch {
            entity.remove(CompatMarker.self)
        }
        return scratch.count
    }

    /// Visits the Position+Velocity+Marker view; empty unless markers were published.
    func visitEventView() -> Int {
        var visited = 0
        CompatSuite.forEachReading(eventView) { position, velocity, marker in
            blackHole(position)
            blackHole(velocity)
            blackHole(marker)
            visited += 1
        }
        return visited
    }

    func pass() -> CompatOutcome {
        var outcome = CompatOutcome()
        if withUpdate {
            // Effective upstream workload: the Position+Velocity update, the (empty) event view, then the marker-pool clear.
            outcome.operations += movement.update(deltaTime: CompatUpdateWorld.deltaTime)
            outcome.operations += visitEventView()
            outcome.hits += clearMarkers()
            outcome.operations += outcome.hits
        } else {
            let published = publishMarkers()
            let cleared = clearMarkers()
            outcome.operations = published + cleared
            outcome.hits = cleared
        }
        return outcome
    }
}
