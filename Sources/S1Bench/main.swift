// swiftlint:disable all
// Spike S1 timing: 1R1W over 10k entities, variant A vs Mut vs 1.x Family. Run: make build-release && .build/release/S1Bench
import FirebladeECS
import S1FamilyAPI

struct BPos: S1Component { static let componentIndex = 0; var x = 0.0; var y = 0.0 }
struct BVel: S1Component { static let componentIndex = 1; var x = 0.0; var y = 0.0 }

final class OldPos: FirebladeECS.Component, @unchecked Sendable { var x = 0.0; var y = 0.0 }
final class OldVel: FirebladeECS.Component, @unchecked Sendable { var x = 0.0; var y = 0.0 }

let entityCount = 10000
let repetitions = 2000

func measure(_ name: String, _ body: () -> Void) {
    body() // warm up
    let clock = ContinuousClock()
    let elapsed = clock.measure { for _ in 0 ..< repetitions {
        body()
    } }
    let perPass = elapsed / repetitions
    print("\(name.padding(toLength: 28, withPad: " ", startingAt: 0)) \(perPass)  per pass of \(entityCount)")
}

let world = World()
for index in 0 ..< entityCount {
    let entity = world.createEntity()
    world.add(BPos(x: Double(index)), to: entity)
    world.add(BVel(), to: entity)
}

let family = S1FamilyAPI.Family(world: world, reading: Reading(BPos.self), writing: Writing(BVel.self))

let nexus = Nexus()
for index in 0 ..< entityCount {
    let entity = nexus.createEntity()
    let pos = OldPos()
    pos.x = Double(index)
    entity.set(pos)
    entity.set(OldVel())
}

let oldFamily = nexus.family(requiresAll: OldPos.self, OldVel.self)

measure("A  (inout tuple)") { family.forEach { (w: inout (BVel), p: BPos) in w.x += p.x } }
measure("Mut (dynamic member)") { family.forEachMut { (p: BPos, v: Mut<BVel>) in v.x += p.x } }
measure("Mut (value accessor)") { family.forEachMut { (p: BPos, v: Mut<BVel>) in v.value.x += p.x } }
measure("per-arity, no packs") { world.forEach(reading: BPos.self, writing: BVel.self) { (p: BPos, v: inout BVel) in v.x += p.x } }
measure("1.x Family iterator") { for (pos, vel) in oldFamily {
    vel.x += pos.x
} }

// Hand-written baseline: the same loop on concrete storage, no packs.
let posStorage = world.storage(BPos.self)
let velStorage = world.storage(BVel.self)
measure("hand-written (no packs)") {
    let posBase = posStorage.mutableBase()
    let velBase = velStorage.mutableBase()
    for index in 0 ..< posStorage.count {
        let id = posStorage.ids[index]
        let velIndex = velStorage.denseIndex(of: id)
        if velIndex >= 0 {
            velBase[velIndex].x += posBase[index].x
        }
    }
}

print(velStorage.dense[entityCount - 1].x)
