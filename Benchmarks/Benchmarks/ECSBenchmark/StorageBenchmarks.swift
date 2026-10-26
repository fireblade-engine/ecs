// swiftformat:disable preferForLoop
import Benchmark
import FirebladeECS

// Benchmarks of the storage itself, ported from the S2 spike (Spikes/S2/REPORT.md on branch spike/s2-storage) and
// run on every storage: the name carries the storage in brackets. The nexus is built before the measurement, so the
// numbers are the operation alone, and the malloc count is the allocations of the operation.
//
// Reductions xor the bit patterns: a floating-point accumulator in the closure would chain on the latency of the
// addition and hide the storage.

struct B0: Component, Sendable { var v: UInt64 = 0 }
struct B1: Component, Sendable { var v: UInt64 = 0 }
struct B2: Component, Sendable { var v: UInt64 = 0 }
struct B3: Component, Sendable { var v: UInt64 = 0 }
struct B4: Component, Sendable { var v: UInt64 = 0 }
struct B5: Component, Sendable { var v: UInt64 = 0 }
struct B6: Component, Sendable { var v: UInt64 = 0 }
struct B7: Component, Sendable { var v: UInt64 = 0 }
struct B8: Component, Sendable { var v: UInt64 = 0 }
struct B9: Component, Sendable { var v: UInt64 = 0 }
struct Toggle: Component, Sendable {}
struct Named: Component, Sendable {
    var name: String
    var count = 0
}

/// Families and entities refer to their nexus without owning it, and the measured closures capture no nexus: the
/// worlds live as long as the process.
private nonisolated(unsafe) var worlds: [Nexus] = []

private let entityCount = 10000
private let largeCount = 100_000
private let sharedName = String(repeating: "named component payload ", count: 4)

/// `count` entities with `B0 ... B6`, the shared base of most cases.
private func makeUniform(_ storage: Nexus.StorageKind, count: Int = entityCount) -> (Nexus, [Entity]) {
    let nexus = Nexus(storage: storage)
    worlds.append(nexus)
    var entities: [Entity] = []
    entities.reserveCapacity(count)
    for _ in 0 ..< count {
        entities.append(nexus.createEntity(with: B0(), B1(), B2(), B3(), B4(), B5(), B6()))
    }
    return (nexus, entities)
}

/// All entities have B0; 10% have B1 as well, the rest are spread over {B0, B2} and {B0, B3}.
private func makeTenPercent(_ storage: Nexus.StorageKind) -> Nexus {
    let nexus = Nexus(storage: storage)
    worlds.append(nexus)
    for index in 0 ..< entityCount {
        let entity = nexus.createEntity(with: B0())
        if index % 10 == 0 {
            entity.set(B1())
        } else if index % 2 == 0 {
            entity.set(B2())
        } else {
            entity.set(B3())
        }
    }
    return nexus
}

/// 1024 distinct component sets: B0, B1 and a different subset of ten tag types per entity group.
private func makeFragmented(_ storage: Nexus.StorageKind) -> (Nexus, [Entity]) {
    let nexus = Nexus(storage: storage)
    worlds.append(nexus)
    var entities: [Entity] = []
    for index in 0 ..< entityCount {
        let entity = nexus.createEntity(with: B0(), B1())
        let bits = index % 1024
        if bits & 1 != 0 {
            entity.set(Tag0())
        }
        if bits & 2 != 0 {
            entity.set(Tag1())
        }
        if bits & 4 != 0 {
            entity.set(Tag2())
        }
        if bits & 8 != 0 {
            entity.set(Tag3())
        }
        if bits & 16 != 0 {
            entity.set(Tag4())
        }
        if bits & 32 != 0 {
            entity.set(Tag5())
        }
        if bits & 64 != 0 {
            entity.set(Tag6())
        }
        if bits & 128 != 0 {
            entity.set(Tag7())
        }
        if bits & 256 != 0 {
            entity.set(Tag8())
        }
        if bits & 512 != 0 {
            entity.set(Tag9())
        }
        entities.append(entity)
    }
    return (nexus, entities)
}

struct Tag0: Component, Sendable {}
struct Tag1: Component, Sendable {}
struct Tag2: Component, Sendable {}
struct Tag3: Component, Sendable {}
struct Tag4: Component, Sendable {}
struct Tag5: Component, Sendable {}
struct Tag6: Component, Sendable {}
struct Tag7: Component, Sendable {}
struct Tag8: Component, Sendable {}
struct Tag9: Component, Sendable {}

/// 100k entities with B0, B1, B2 whose B1 and B2 storage order is permuted against B0.
private func makeShuffled(_ storage: Nexus.StorageKind) -> Nexus {
    let nexus = Nexus(storage: storage)
    worlds.append(nexus)
    let entities = (0 ..< largeCount).map { _ in nexus.createEntity(with: B0(), B1(), B2()) }
    var generator = SystemRandomNumberGenerator()
    for entity in entities.shuffled(using: &generator) {
        entity.remove(B1.self)
        entity.remove(B2.self)
    }
    for entity in entities.shuffled(using: &generator) {
        entity.set(B1())
        entity.set(B2())
    }
    return nexus
}

func storageBenchmarks() {
    func register(_ name: String, prepare: @escaping @Sendable (Nexus.StorageKind) -> () -> Void) {
        for storage in Nexus.StorageKind.allCases {
            Benchmark("\(name) [\(storage)]") { benchmark in
                let run = prepare(storage)
                benchmark.startMeasurement()
                for _ in benchmark.scaledIterations {
                    run()
                }
                benchmark.stopMeasurement()
            }
        }
    }

    // MARK: iteration

    register("S2Iterate1Read") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requires: B0.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self) { s ^= $0.v }; blackHole(s) }
    }
    register("S2Iterate2Reads") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self) { s ^= $0.v ^ $1.v }; blackHole(s) }
    }
    register("S2Iterate4Reads") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self, B2.self, B3.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self, B2.self, B3.self) { s ^= $0.v ^ $1.v ^ $2.v ^ $3.v }; blackHole(s) }
    }
    register("S2Iterate1R1W") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { family.forEach(reading: B0.self, writing: B1.self) { read, write in write.v &+= read.v } }
    }
    register("S2Iterate2R1W") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self, B2.self)
        return { family.forEach(reading: B0.self, B1.self, writing: B2.self) { first, second, write in write.v &+= first.v &+ second.v } }
    }
    // above the generated arities: the parameter pack fallback
    register("S2IteratePack5R2W") { storage in
        let (nexus, _) = makeUniform(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self, B2.self, B3.self, B4.self, B5.self, B6.self)
        return { family.forEach(reading: B0.self, B1.self, B2.self, B3.self, B4.self, writing: B5.self, B6.self) { (written: inout (B5, B6), a, b, c, d, e) in
            written.0.v &+= a.v &+ b.v
            written.1.v &+= c.v &+ d.v &+ e.v
        } }
    }
    register("S2Iterate2ReadsTenPercent") { storage in
        let nexus = makeTenPercent(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self) { s ^= $0.v ^ $1.v }; blackHole(s) }
    }
    register("S2Iterate1R1WTenPercent") { storage in
        let nexus = makeTenPercent(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { family.forEach(reading: B0.self, writing: B1.self) { read, write in write.v &+= read.v } }
    }
    register("S2Iterate2ReadsExcluding") { storage in
        let nexus = makeTenPercent(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self, excludesAll: B2.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self) { s ^= $0.v ^ $1.v }; blackHole(s) }
    }
    register("S2IterateShuffled100k2Reads") { storage in
        let nexus = makeShuffled(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self) { s ^= $0.v ^ $1.v }; blackHole(s) }
    }
    register("S2IterateShuffled100k1R1W") { storage in
        let nexus = makeShuffled(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { family.forEach(reading: B0.self, writing: B1.self) { read, write in write.v &+= read.v } }
    }
    register("S2IterateString1R1W") { storage in
        let (nexus, entities) = makeUniform(storage)
        for entity in entities {
            entity.set(Named(name: sharedName))
        }
        let family = nexus.family(requiresAll: B0.self, Named.self)
        return { family.forEach(reading: B0.self, writing: Named.self) { read, write in write.count &+= Int(truncatingIfNeeded: read.v & 1) } }
    }
    register("S2IterateFragmented2Reads") { storage in
        let (nexus, _) = makeFragmented(storage)
        let family = nexus.family(requiresAll: B0.self, B1.self)
        return { var s: UInt64 = 0; family.forEach(reading: B0.self, B1.self) { s ^= $0.v ^ $1.v }; blackHole(s) }
    }

    // MARK: random access

    register("S2RandomGet") { storage in
        let (_, entities) = makeUniform(storage)
        var generator = SystemRandomNumberGenerator()
        let order = entities.shuffled(using: &generator)
        return { var s: UInt64 = 0; for entity in order {
            s ^= entity.get(B0.self)?.v ?? 0
        }; blackHole(s) }
    }
    register("S2RandomGetFragmented") { storage in
        let (_, entities) = makeFragmented(storage)
        var generator = SystemRandomNumberGenerator()
        let order = entities.shuffled(using: &generator)
        return { var s: UInt64 = 0; for entity in order {
            s ^= entity.get(B0.self)?.v ?? 0
        }; blackHole(s) }
    }

    // MARK: structural churn

    // One run adds the component to all 10k entities and removes it again: 20k structural changes.
    register("S2ChurnAddRemoveTag10k") { storage in
        let (_, entities) = makeUniform(storage)
        return {
            for entity in entities {
                entity.set(Toggle())
            }
            for entity in entities {
                entity.remove(Toggle.self)
            }
        }
    }
    register("S2ChurnAddRemovePayload10k") { storage in
        let (_, entities) = makeUniform(storage)
        return {
            for entity in entities {
                entity.set(B9())
            }
            for entity in entities {
                entity.remove(B9.self)
            }
        }
    }
    register("S2ChurnAddRemoveString10k") { storage in
        let (_, entities) = makeUniform(storage)
        return {
            for entity in entities {
                entity.set(Named(name: sharedName))
            }
            for entity in entities {
                entity.remove(Named.self)
            }
        }
    }
    register("S2ChurnAddRemoveTag1k") { storage in
        let (_, entities) = makeUniform(storage)
        let tenth = Array(entities.prefix(entityCount / 10))
        return {
            for entity in tenth {
                entity.set(Toggle())
            }
            for entity in tenth {
                entity.remove(Toggle.self)
            }
        }
    }
    // entity creation and destruction with seven components
    register("S2CreateDestroy1k") { storage in
        let nexus = Nexus(storage: storage)
        worlds.append(nexus)
        return {
            let created = (0 ..< 1000).map { _ in nexus.createEntity(with: B0(), B1(), B2(), B3(), B4(), B5(), B6()) }
            for entity in created {
                nexus.destroy(entity: entity)
            }
        }
    }
}
