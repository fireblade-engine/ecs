// swiftlint:disable all
// Spike S2 benchmarks: sparse set vs archetype vs block-allocated sparse set.
// Run: make build-release && .build/release/S2Bench
import Darwin
import Foundation
import S2Storage

let entityCount = 10000

nonisolated(unsafe) var sink = 0.0
nonisolated(unsafe) var allocationCount = 0

/// Counts every malloc-family allocation through libmalloc's logging hook (macOS only).
typealias MallocLogger = @convention(c) (UInt32, UInt, UInt, UInt, UInt, UInt32) -> Void

func installAllocationCounter() {
    guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "malloc_logger") else {
        fatalError("malloc_logger is not available")
    }
    symbol.assumingMemoryBound(to: MallocLogger?.self).pointee = { type, _, _, _, _, _ in
        if type & 2 != 0 {
            allocationCount &+= 1
        }
    }
}

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

func allocations(_ body: () -> Void) -> Int {
    body()
    let before = allocationCount
    for _ in 0 ..< 100 {
        body()
    }
    return (allocationCount - before) / 100
}

func makeUniform<S: NexusStorageProviding>(_: S.Type, payload: Int) -> (S, [EntityID]) {
    let storage = S()
    var entities: [EntityID] = []
    for _ in 0 ..< entityCount {
        let entity = storage.createEntity()
        addPayload(storage, entity, count: payload)
        entities.append(entity)
    }
    return (storage, entities)
}

/// All entities have C0; 10% have C1 as well (set A), the rest are spread over {C0,C2} and {C0,C3}.
func makeTenPercent<S: NexusStorageProviding>(_: S.Type) -> S {
    let storage = S()
    for index in 0 ..< entityCount {
        let entity = storage.createEntity()
        storage.set(C0(), for: entity)
        if index % 10 == 0 {
            storage.set(C1(), for: entity)
        } else {
            index % 2 == 0 ? storage.set(C2(), for: entity) : storage.set(C3(), for: entity)
        }
    }
    return storage
}

/// 1024 distinct component sets: C0, C1 and a different subset of ten tag types per entity group.
func makeFragmented<S: NexusStorageProviding>(_: S.Type) -> (S, [EntityID]) {
    let storage = S()
    var entities: [EntityID] = []
    for index in 0 ..< entityCount {
        let entity = storage.createEntity()
        storage.set(C0(), for: entity)
        storage.set(C1(), for: entity)
        addTags(storage, entity, bits: index % 1024)
        entities.append(entity)
    }
    return (storage, entities)
}

struct Row {
    var name: String
    var value: Double
}

func runAll<S: NexusStorageProviding>(_ type: S.Type) -> [Row] {
    var rows: [Row] = []
    func add(_ name: String, _ body: () -> Void) {
        rows.append(Row(name: name, value: measure(body)))
    }
    func record(_ name: String, _ value: Double) {
        rows.append(Row(name: name, value: value))
    }

    let (full, fullEntities) = makeUniform(S.self, payload: 20)

    add("iterate 1 read (10k)") { var s = 0.0; full.forEach(reading: C0.self) { s += $0.v }; sink += s }
    add("iterate 2 reads (10k)") { var s = 0.0; full.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }; sink += s }
    add("iterate 4 reads (10k)") { var s = 0.0; full.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s += $0.v + $1.v + $2.v + $3.v }; sink += s }
    add("iterate 1R1W (10k)") { full.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }
    add("iterate 2R1W (10k)") { full.forEach(reading: C0.self, C1.self, writing: C2.self) { r0, r1, w in w.v += r0.v + r1.v } }
    add("iterate 8 reads, pack (10k)") { sink += sumPack8(full) }
    add("iterate 16 reads, pack (10k)") { sink += sumPack16(full) }
    add("iterate 20 reads, pack (10k)") { sink += sumPack20(full) }

    let tenPercent = makeTenPercent(S.self)
    add("iterate 2 reads, 10% match") { var s = 0.0; tenPercent.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }; sink += s }
    add("iterate 1R1W, 10% match") { tenPercent.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }

    let excluded = FamilyFilter(excludes: ComponentMask(C2.self))
    add("iterate 2 reads, excl. C2") { var s = 0.0; tenPercent.forEach(reading: C0.self, C1.self, where: excluded) { s += $0.v + $1.v }; sink += s }

    // Churn: entities with four components, toggle a tag every frame.
    do {
        let (churn, entities) = makeUniform(S.self, payload: 4)
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
        let (churnPayload, entitiesPayload) = makeUniform(S.self, payload: 4)
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
        let (churn10, entities10) = makeUniform(S.self, payload: 4)
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
        // Iteration cost right after churn (the family now spans two tables / a permuted dense array).
        for e in entities {
            churn.set(Toggle(), for: e)
        }
        for e in entities.prefix(entityCount / 2) {
            churn.remove(Toggle.self, from: e)
        }
        add("iterate 2 reads after churn") { var s = 0.0; churn.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }; sink += s }
    }

    // Fragmentation.
    let (fragmented, fragEntities) = makeFragmented(S.self)
    if let archetype = fragmented as? ArchetypeStorage {
        record("(fragmented world: tables)", Double(archetype.tableCount))
    }
    add("fragmented: iterate 2 reads (10k, 1024 sets)") { var s = 0.0; fragmented.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }; sink += s }

    // Random access.
    var generator = SystemRandomNumberGenerator()
    let shuffled = fullEntities.shuffled(using: &generator)
    add("random get C0 (10k, per pass)") { var s = 0.0; for e in shuffled {
        s += full.get(C0.self, for: e)?.v ?? 0
    }; sink += s }
    let fragShuffled = fragEntities.shuffled(using: &generator)
    add("fragmented: random get C0 (10k, per pass)") { var s = 0.0; for e in fragShuffled {
        s += fragmented.get(C0.self, for: e)?.v ?? 0
    }; sink += s }

    // Allocations per pass (not microseconds): must be 0 per entity.
    _ = allocations { var s = 0.0; full.forEach(reading: C0.self) { s += $0.v }; sink += s }
    let allocationRows = [
        ("allocs/pass: iterate 1 read", allocations { var s = 0.0; full.forEach(reading: C0.self) { s += $0.v }; sink += s }),
        ("allocs/pass: iterate 4 reads", allocations { var s = 0.0; full.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s += $0.v + $1.v + $2.v + $3.v }; sink += s }),
        ("allocs/pass: iterate 1R1W", allocations { full.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }),
        ("allocs/pass: iterate 20 reads, pack", allocations { sink += sumPack20(full) }),
        ("allocs/pass: fragmented 2 reads", allocations { var s = 0.0; fragmented.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }; sink += s })
    ]
    for (name, count) in allocationRows {
        record(name, Double(count))
    }
    return rows
}

func rawArrayBaseline() -> Double {
    let values = [Double](repeating: 1, count: entityCount)
    return measure { var s = 0.0; for v in values {
        s += v
    }; sink += s }
}

if CommandLine.arguments.contains("--profile-fragmented") {
    // Spin on the fragmented archetype iteration so an external sampler can attribute the cost.
    let (fragmented, _) = makeFragmented(ArchetypeStorage.self)
    while true {
        var s = 0.0
        fragmented.forEach(reading: C0.self, C1.self) { s += $0.v + $1.v }
        sink += s
    }
}

/// Allocations per pass in a clean process state: one world, nothing else alive.
func allocationGate<S: NexusStorageProviding>(_ type: S.Type) {
    let (world, _) = makeUniform(S.self, payload: 20)
    let one = allocations { var s = 0.0; world.forEach(reading: C0.self) { s += $0.v }; sink += s }
    let four = allocations { var s = 0.0; world.forEach(reading: C0.self, C1.self, C2.self, C3.self) { s += $0.v + $1.v + $2.v + $3.v }; sink += s }
    let write = allocations { world.forEach(reading: C0.self, writing: C1.self) { r, w in w.v += r.v } }
    let pack = allocations { sink += sumPack20(world) }
    print("\(S.self): allocations per pass of \(entityCount) entities: 1R \(one), 4R \(four), 1R1W \(write), 20R pack \(pack)")
}

if CommandLine.arguments.contains("--allocations") {
    installAllocationCounter()
    allocationGate(SparseSetStorage.self)
    allocationGate(ArchetypeStorage.self)
    allocationGate(BlockSparseSetStorage.self)
    exit(0)
}

installAllocationCounter()
let sparse = runAll(SparseSetStorage.self)
let archetype = runAll(ArchetypeStorage.self)
let block = runAll(BlockSparseSetStorage.self)

func format(_ value: Double) -> String {
    value >= 100 ? String(format: "%.0f", value) : value >= 10 ? String(format: "%.1f", value) : String(format: "%.2f", value)
}

print("| case | SparseSet | Archetype | BlockSparseSet |")
print("| --- | ---: | ---: | ---: |")
for index in sparse.indices {
    let name = sparse[index].name
    print("| \(name) | \(format(sparse[index].value)) | \(format(archetype[index].value)) | \(format(block[index].value)) |")
}

print("raw [Double] sum of \(entityCount): \(format(rawArrayBaseline())) us")
print("sink \(sink)")
