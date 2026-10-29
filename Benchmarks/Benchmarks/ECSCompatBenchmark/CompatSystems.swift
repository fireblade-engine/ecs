// Payloads, systems and worlds of the update and event workloads, ported from the reference benchmarks in ECSBenchmark.
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

enum CompatPlayerType: Int32, Sendable { case npc = 0, monster = 1, hero = 2 }

struct CompatPlayerPayload: Sendable {
    var rng: CompatXoshiro128
    var type: CompatPlayerType = .npc
}

struct CompatHealthPayload: Sendable { var hp: Int32 = 0, maxhp: Int32 = 0 }
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

struct CompatMoreComplexSystem {
    let family: Family<CompatPosition, CompatVelocity, CompatData>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatPosition.self, CompatVelocity.self, CompatData.self)
    }

    func update(deltaTime: Float) -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write2(family) { position, velocity, data in
            let bump = Float(data.payload.thingy & 3)
            velocity.payload.x += bump * deltaTime
            velocity.payload.y += bump * deltaTime
            _ = position
            visited += 1
        }
        return visited
    }
}

struct CompatHealthSystem {
    let family: Family<CompatHealth>

    init(nexus: Nexus) {
        family = nexus.family(requires: CompatHealth.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachWriting(family) { health in
            if health.payload.hp > health.payload.maxhp { health.payload.hp = health.payload.maxhp }
            visited += 1
        }
        return visited
    }
}

struct CompatDamageSystem {
    let family: Family<CompatDamage, CompatHealth>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatDamage.self, CompatHealth.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write1(family) { damage, health in
            health.payload.hp = health.payload.hp &- damage.payload.atk
            visited += 1
        }
        return visited
    }
}

struct CompatSpriteSystem {
    let family: Family<CompatHealth, CompatSprite>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: CompatHealth.self, CompatSprite.self)
    }

    func update() -> Int {
        var visited = 0
        CompatSuite.forEachRead1Write1(family) { health, sprite in
            sprite.payload.character = health.payload.hp > 0 ? 65 : 66
            visited += 1
        }
        return visited
    }
}

struct CompatRenderSystem {
    let family: Family<CompatPosition>

    init(nexus: Nexus) {
        family = nexus.family(requires: CompatPosition.self)
    }

    func update(accumulator: inout Float) -> Int {
        var visited = 0
        var sum: Float = 0
        CompatSuite.forEachReading(family) { position in
            sum += position.payload.x + position.payload.y
            visited += 1
        }
        accumulator += sum
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
    private(set) var accumulator: Float = 0

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
            visits.append(moreComplex.update(deltaTime: dt))
            visits.append(health.update())
            visits.append(damage.update())
            visits.append(sprite.update())
            var accumulator = 0 as Float
            visits.append(render.update(accumulator: &accumulator))
            self.accumulator = accumulator
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
