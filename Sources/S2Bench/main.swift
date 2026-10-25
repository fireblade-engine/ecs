// swiftlint:disable all
// Spike S2 benchmarks, run through the closed-enum `S2Nexus`: sparse set vs archetype.
// Run: make build-release && .build/release/S2Bench            (full table)
//      .build/release/S2Bench --allocations                    (clean-process allocation gate, macOS only)
//      .build/release/S2Bench --profile-fragmented             (spin for an external sampler)
#if canImport(Darwin)
    import Darwin
#endif
import Foundation
import S2Storage

let entityCount = 10000
let largeCount = 100_000

nonisolated(unsafe) var sink: UInt64 = 0

// MARK: Allocation counting (macOS only)

#if canImport(Darwin)
    nonisolated(unsafe) var allocationCount = 0
    nonisolated(unsafe) var measuringThread: UInt32 = 0
    nonisolated(unsafe) var capturedStacks: [[UnsafeMutableRawPointer?]] = []
    nonisolated(unsafe) var captureStacks = false
    nonisolated(unsafe) var capturing = false

    typealias MallocLogger = @convention(c) (UInt32, UInt, UInt, UInt, UInt, UInt32) -> Void

    /// Counts libmalloc allocations made by the measuring thread through the `malloc_logger` hook.
    func installAllocationCounter() {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "malloc_logger") else {
            fatalError("malloc_logger is not available")
        }
        measuringThread = pthread_mach_thread_np(pthread_self())
        symbol.assumingMemoryBound(to: MallocLogger?.self).pointee = { type, _, _, _, _, _ in
            guard type & 2 != 0, pthread_mach_thread_np(pthread_self()) == measuringThread, !capturing else { return }
            allocationCount &+= 1
            if captureStacks, capturedStacks.count < 3 {
                capturing = true
                var frames = [UnsafeMutableRawPointer?](repeating: nil, count: 24)
                let depth = backtrace(&frames, 24)
                capturedStacks.append(Array(frames.prefix(Int(depth))))
                capturing = false
            }
        }
    }

    /// Allocations per pass: the minimum over several trials. The first nonzero result prints the stacks of the
    /// first allocations so a regression can be attributed.
    func allocations(_ name: String, _ body: () -> Void) -> Int {
        body()
        var best = Int.max
        for _ in 0 ..< 7 {
            let before = allocationCount
            for _ in 0 ..< 100 {
                body()
            }
            best = min(best, (allocationCount - before) / 100)
        }
        if best > 0 {
            captureStacks = true
            capturedStacks = []
            for _ in 0 ..< 100 {
                body()
            }
            captureStacks = false
            for stack in capturedStacks {
                print("allocation in '\(name)':")
                stack.withUnsafeBufferPointer { buffer in
                    if let symbols = backtrace_symbols(buffer.baseAddress!, Int32(buffer.count)) {
                        for index in 0 ..< buffer.count {
                            print("    \(String(cString: symbols[index]!))")
                        }
                    }
                }
            }
        }
        return best
    }
#else
    func installAllocationCounter() {}
    func allocations(_ name: String, _ body: () -> Void) -> Int {
        -1
    }
#endif

// MARK: Timing

/// Mean time of one `body` call in microseconds: best of five batches, each batch sized to about 40 ms.
func measure(_ body: () -> Void) -> Double {
    body()
    let clock = ContinuousClock()
    var reps = 1
    while true {
        let elapsed = clock.measure { for _ in 0 ..< reps {
            body()
        } }
        if elapsed > .milliseconds(40) || reps > 1 << 20 {
            break
        }
        reps *= 2
    }
    var best = Double.infinity
    for _ in 0 ..< 5 {
        let elapsed = clock.measure { for _ in 0 ..< reps {
            body()
        } }
        let micros = Double(elapsed.components.seconds) * 1e6 + Double(elapsed.components.attoseconds) / 1e12
        best = min(best, micros / Double(reps))
    }
    return best
}

// MARK: Worlds

func makeUniform(_ kind: S2Nexus.StorageKind, payload: Int, count: Int = entityCount) -> (S2Nexus, [EntityID]) {
    let nexus = S2Nexus(storage: kind)
    var entities: [EntityID] = []
    entities.reserveCapacity(count)
    for _ in 0 ..< count {
        let entity = nexus.createEntity()
        addPayload(nexus, entity, count: payload)
        entities.append(entity)
    }
    return (nexus, entities)
}

/// All entities have C0; 10% have C1 as well, the rest are spread over {C0,C2} and {C0,C3}.
func makeTenPercent(_ kind: S2Nexus.StorageKind) -> S2Nexus {
    let nexus = S2Nexus(storage: kind)
    for index in 0 ..< entityCount {
        let entity = nexus.createEntity()
        nexus.set(C0(), for: entity)
        if index % 10 == 0 {
            nexus.set(C1(), for: entity)
        } else if index % 2 == 0 {
            nexus.set(C2(), for: entity)
        } else {
            nexus.set(C3(), for: entity)
        }
    }
    return nexus
}

/// 1024 distinct component sets: C0, C1 and a different subset of ten tag types per entity group.
func makeFragmented(_ kind: S2Nexus.StorageKind) -> (S2Nexus, [EntityID]) {
    let nexus = S2Nexus(storage: kind)
    var entities: [EntityID] = []
    for index in 0 ..< entityCount {
        let entity = nexus.createEntity()
        nexus.set(C0(), for: entity)
        nexus.set(C1(), for: entity)
        addTags(nexus, entity, bits: index % 1024)
        entities.append(entity)
    }
    return (nexus, entities)
}

/// 100k entities with C0, C1, C2 whose C1 and C2 dense arrays are permuted relative to C0: created in order,
/// then C1 and C2 are removed and re-added in random order.
func makeShuffled(_ kind: S2Nexus.StorageKind) -> S2Nexus {
    let (nexus, entities) = makeUniform(kind, payload: 3, count: largeCount)
    var generator = SystemRandomNumberGenerator()
    for entity in entities.shuffled(using: &generator) {
        nexus.remove(C1.self, from: entity)
        nexus.remove(C2.self, from: entity)
    }
    for entity in entities.shuffled(using: &generator) {
        nexus.set(C1(), for: entity)
        nexus.set(C2(), for: entity)
    }
    return nexus
}

// MARK: Cases

struct Row {
    var name: String
    var value: Double
}

let sharedName = String(repeating: "named component payload ", count: 4)

func runAll(_ kind: S2Nexus.StorageKind) -> [Row] {
    var rows: [Row] = []
    func add(_ name: String, _ body: () -> Void) {
        rows.append(Row(name: name, value: measure(body)))
    }
    func record(_ name: String, _ value: Double) {
        rows.append(Row(name: name, value: value))
    }

    let (full, fullEntities) = makeUniform(kind, payload: 20)

    // The reductions xor the bit patterns: a one-cycle dependency chain, so the loop measures the storage
    // and not the four-cycle latency of a floating-point accumulator.
    add("iterate 1 read (10k)") { var s: UInt64 = 0; full.forEach(reading: C0.self) { s ^= $0.v.bitPattern }; sink ^= s }
    add("iterate 2 reads (10k)") { var s: UInt64 = 0; full.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }
    add("iterate 4 reads (10k)") { var s: UInt64 = 0; full.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s }
    add("iterate 1R1W (10k)") { full.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }
    add("iterate 2R1W (10k)") { full.forEach(reading: C0.self, C1.self, writing: C2.self) { r0, r1, w in w.v += r0.v + r1.v } }
    add("iterate 8 reads, pack (10k)") { sink ^= sumPack8(full).bitPattern }
    add("iterate 16 reads, pack (10k)") { sink ^= sumPack16(full).bitPattern }
    add("iterate 20 reads, pack (10k)") { sink ^= sumPack20(full).bitPattern }

    let tenPercent = makeTenPercent(kind)
    add("iterate 2 reads, 10% match") { var s: UInt64 = 0; tenPercent.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }
    add("iterate 1R1W, 10% match") { tenPercent.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }
    let excluded = FamilyFilter(excludes: ComponentMask(C2.self))
    add("iterate 2 reads, excl. C2") { var s: UInt64 = 0; tenPercent.forEach(reading: C0.self, C1.self, where: excluded) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }

    // 100k entities, dense arrays permuted against each other.
    let shuffled = makeShuffled(kind)
    add("100k shuffled: iterate 2 reads") { var s: UInt64 = 0; shuffled.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }
    add("100k shuffled: iterate 1R1W") { shuffled.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }

    // Non-trivial component (String field).
    do {
        let (named, entities) = makeUniform(kind, payload: 1)
        for entity in entities {
            named.set(Named(name: sharedName), for: entity)
        }
        add("String component: iterate 1R1W (10k)") { named.forEach(reading: C0.self, writing: Named.self) { r, w in w.count &+= Int(truncatingIfNeeded: r.v.bitPattern & 1) } }
        var present = true
        add("String component: toggle on 10k (per frame)") {
            if present {
                for e in entities {
                    named.remove(Named.self, from: e)
                }
            } else {
                for e in entities {
                    named.set(Named(name: sharedName), for: e)
                }
            }
            present.toggle()
        }
    }

    // Churn: entities with four components, toggle a tag every frame.
    do {
        let (churn, entities) = makeUniform(kind, payload: 4)
        var present = false
        add("churn: toggle tag on 10k (per frame)") {
            if present {
                for e in entities {
                    churn.remove(Toggle.self, from: e)
                }
            } else {
                for e in entities {
                    churn.set(Toggle(), for: e)
                }
            }
            present.toggle()
        }
        let (churnPayload, entitiesPayload) = makeUniform(kind, payload: 4)
        var presentPayload = false
        add("churn: toggle 8-byte payload on 10k (per frame)") {
            if presentPayload {
                for e in entitiesPayload {
                    churnPayload.remove(C19.self, from: e)
                }
            } else {
                for e in entitiesPayload {
                    churnPayload.set(C19(), for: e)
                }
            }
            presentPayload.toggle()
        }
        let (churn10, entities10) = makeUniform(kind, payload: 4)
        let tenth = Array(entities10.prefix(entityCount / 10))
        var present10 = false
        add("churn: toggle tag on 1k (per frame)") {
            if present10 {
                for e in tenth {
                    churn10.remove(Toggle.self, from: e)
                }
            } else {
                for e in tenth {
                    churn10.set(Toggle(), for: e)
                }
            }
            present10.toggle()
        }
        for e in entities {
            churn.set(Toggle(), for: e)
        }
        for e in entities.prefix(entityCount / 2) {
            churn.remove(Toggle.self, from: e)
        }
        add("iterate 2 reads after churn") { var s: UInt64 = 0; churn.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }
    }

    // Fragmentation.
    let (fragmented, fragEntities) = makeFragmented(kind)
    add("fragmented: iterate 2 reads (10k, 1024 sets)") { var s: UInt64 = 0; fragmented.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }

    // Random access.
    var generator = SystemRandomNumberGenerator()
    let order = fullEntities.shuffled(using: &generator)
    add("random get C0 (10k, per pass)") { var s: UInt64 = 0; for e in order {
        s ^= full.get(C0.self, for: e)?.v.bitPattern ?? 0
    }; sink ^= s }
    let fragOrder = fragEntities.shuffled(using: &generator)
    add("fragmented: random get C0 (10k, per pass)") { var s: UInt64 = 0; for e in fragOrder {
        s ^= fragmented.get(C0.self, for: e)?.v.bitPattern ?? 0
    }; sink ^= s }

    // Allocations per pass (a count, not microseconds): must be 0.
    record("allocs/pass: iterate 1 read", Double(allocations("1R") { var s: UInt64 = 0; full.forEach(reading: C0.self) { s ^= $0.v.bitPattern }; sink ^= s }))
    record("allocs/pass: iterate 4 reads", Double(allocations("4R") { var s: UInt64 = 0; full.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s }))
    record("allocs/pass: iterate 1R1W", Double(allocations("1R1W") { full.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }))
    record("allocs/pass: iterate 20 reads, pack", Double(allocations("pack20") { sink ^= sumPack20(full).bitPattern }))
    record("allocs/pass: fragmented 2 reads", Double(allocations("frag") { var s: UInt64 = 0; fragmented.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }; sink ^= s }))
    return rows
}

/// Direct-storage rows: the same loops without the enum switch, to price the dispatch.
func directRows() -> [(String, Double, Double)] {
    let sparse = SparseSetStorage()
    let archetype = ArchetypeStorage()
    let (viaSparse, _) = makeUniform(.sparseSet, payload: 4)
    let (viaArchetype, _) = makeUniform(.archetype, payload: 4)
    for _ in 0 ..< entityCount {
        let a = sparse.createEntity(), b = archetype.createEntity()
        for storageSet in [0] {
            _ = storageSet
        }
        sparse.set(C0(), for: a); sparse.set(C1(), for: a); sparse.set(C2(), for: a); sparse.set(C3(), for: a)
        archetype.set(C0(), for: b); archetype.set(C1(), for: b); archetype.set(C2(), for: b); archetype.set(C3(), for: b)
    }
    var rows: [(String, Double, Double)] = []
    let direct4 = (
        measure { var s: UInt64 = 0; sparse.forEach(reading: C0.self, C1.self, C2.self, C3.self, where: .none) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s },
        measure { var s: UInt64 = 0; archetype.forEach(reading: C0.self, C1.self, C2.self, C3.self, where: .none) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s }
    )
    let nexus4 = (
        measure { var s: UInt64 = 0; viaSparse.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s },
        measure { var s: UInt64 = 0; viaArchetype.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s }
    )
    rows.append(("iterate 4 reads (10k): direct storage", direct4.0, direct4.1))
    rows.append(("iterate 4 reads (10k): through S2Nexus", nexus4.0, nexus4.1))
    let entities = (0 ..< entityCount).map { EntityID(index: UInt32($0)) }
    let getDirect = (
        measure { var s: UInt64 = 0; for e in entities {
            s ^= sparse.get(C0.self, for: e)?.v.bitPattern ?? 0
        }; sink ^= s },
        measure { var s: UInt64 = 0; for e in entities {
            s ^= archetype.get(C0.self, for: e)?.v.bitPattern ?? 0
        }; sink ^= s }
    )
    let getNexus = (
        measure { var s: UInt64 = 0; for e in entities {
            s ^= viaSparse.get(C0.self, for: e)?.v.bitPattern ?? 0
        }; sink ^= s },
        measure { var s: UInt64 = 0; for e in entities {
            s ^= viaArchetype.get(C0.self, for: e)?.v.bitPattern ?? 0
        }; sink ^= s }
    )
    rows.append(("get C0 in entity order (10k): direct storage", getDirect.0, getDirect.1))
    rows.append(("get C0 in entity order (10k): through S2Nexus", getNexus.0, getNexus.1))
    return rows
}

func format(_ value: Double) -> String {
    value >= 100 ? String(format: "%.0f", value) : value >= 10 ? String(format: "%.1f", value) : String(format: "%.2f", value)
}

// MARK: Entry points

if CommandLine.arguments.contains("--profile-fragmented") {
    let (fragmented, _) = makeFragmented(.archetype)
    while true {
        var s: UInt64 = 0
        fragmented.forEach(reading: C0.self, C1.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern }
        sink ^= s
    }
}

if CommandLine.arguments.contains("--allocations") {
    #if canImport(Darwin)
        installAllocationCounter()
        for kind in S2Nexus.StorageKind.allCases {
            let (world, _) = makeUniform(kind, payload: 20)
            let one = allocations("1R") { var s: UInt64 = 0; world.forEach(reading: C0.self) { s ^= $0.v.bitPattern }; sink ^= s }
            let four = allocations("4R") { var s: UInt64 = 0; world.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s ^= $0.v.bitPattern ^ $1.v.bitPattern ^ $2.v.bitPattern ^ $3.v.bitPattern }; sink ^= s }
            let write = allocations("1R1W") { world.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }
            let pack = allocations("pack20") { sink ^= sumPack20(world).bitPattern }
            print("\(kind): allocations per pass of \(entityCount) entities: 1R \(one), 4R \(four), 1R1W \(write), 20R pack \(pack)")
        }
    #else
        print("allocation check skipped: it needs the macOS malloc_logger hook")
    #endif
    exit(0)
}

installAllocationCounter()
let sparseRows = runAll(.sparseSet)
let archetypeRows = runAll(.archetype)

print("| case | sparse set | archetype |")
print("| --- | ---: | ---: |")
for index in sparseRows.indices {
    print("| \(sparseRows[index].name) | \(format(sparseRows[index].value)) | \(format(archetypeRows[index].value)) |")
}

print()
print("| dispatch cost | sparse set | archetype |")
print("| --- | ---: | ---: |")
for (name, sparse, archetype) in directRows() {
    print("| \(name) | \(format(sparse)) | \(format(archetype)) |")
}

let rawValues = [UInt64](repeating: 1, count: entityCount)
print("raw [UInt64] xor over \(entityCount) elements: \(format(measure { var s: UInt64 = 0; for v in rawValues { s ^= v }; sink ^= s })) us (floor)")
print("sink \(sink)")
