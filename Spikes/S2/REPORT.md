# Spike S2: `NexusStorageProviding`, sparse set vs archetype (decision D3)

Branch `spike/s2-storage`. Code: `Sources/S2Storage` (protocol and storages, carries into M1), `Tests/S2StorageTests`
(shared conformance suite, carries), `Sources/S2Bench` (spike only). Toolchain Swift 6.4 on an Apple M1 Max; the
Swift 6.2 evidence has to come from CI.

## Recommendation

**`.default` is `SparseSetStorage`.** Both storages stay behind `NexusStorageProviding` (D3); the archetype
storage is the opt-in for worlds that iterate big, stable families and rarely change component sets.

Why:

- Sparse set is the only storage with no bad case. Its worst measured number is 3.4 ns per entity for a
  family (a few sparse lookups per entity). Archetype wins that case by 3.7x (reads) to 5.4x (writes), but its
  two bad cases are 10x (churn) and 30x (fragmentation) behind.
- Component churn (FSM state changes, tags toggled per frame) costs 12 ns per add or remove on a sparse set and
  115 ns on archetype, which moves the whole row.
- Fragmentation: 1,024 distinct component sets cost archetype 1.0 us per table visited (1026 us per pass of 10k
  entities against 34 us). Component sets in a game are not under the engine's control; per-table cost is.
- Random access and 10%-match families are equal or better on sparse set (it drives from the smallest storage).
- Iteration at 3.4 ns per entity is 34 us per 10k entities, so a 60 Hz frame spends 0.2% of its budget per family
  per 10k entities. The archetype advantage only matters for workloads with many large families.

## Numbers

Microseconds per pass (10k entities, all members unless stated), best of five batches, release build,
`.build/release/S2Bench`. A raw `[Double]` sum over 10k elements takes 9.2 us.

| case | SparseSet | Archetype | BlockSparseSet |
| --- | ---: | ---: | ---: |
| iterate 1 read | 9.46 | 9.25 | 9.33 |
| iterate 2 reads | 35.2 | 9.29 | 34.3 |
| iterate 4 reads | 34.5 | 9.32 | 35.2 |
| iterate 1R1W | 12.5 | 2.32 | 16.5 |
| iterate 2R1W | 17.7 | 3.26 | 23.3 |
| iterate 8 reads, pack | 1450 | 77.7 | 1522 |
| iterate 16 reads, pack | 2931 | 162 | 3057 |
| iterate 20 reads, pack | 3627 | 527 | 3768 |
| iterate 2 reads, 10% match | 3.47 | 0.85 | 3.49 |
| iterate 1R1W, 10% match | 2.05 | 0.14 | 2.30 |
| iterate 2 reads, excl. C2 | 3.70 | 0.85 | 3.73 |
| churn: toggle tag on 10k, per frame | 124 | 1148 | 99.3 |
| churn: toggle 8-byte payload on 10k, per frame | 126 | 1133 | 99.5 |
| churn: toggle tag on 1k, per frame | 12.4 | 113 | 9.93 |
| iterate 2 reads after churn | 34.1 | 9.24 | 34.2 |
| fragmented (1024 sets): iterate 2 reads | 34.1 | 1026 | 34.2 |
| random `get` of C0, 10k lookups | 12.7 | 9.43 | 15.7 |
| fragmented: random `get` of C0, 10k lookups | 12.6 | 21.7 | 14.7 |

Notes on the cases:

- 1R is a dense scan in sparse set (no lookups), hence equal to the raw loop. From 2 reads on, sparse set pays
  one sparse lookup per extra component: about 3.4 ns per entity for 2 and for 4 reads (the cost is the random
  dependent loads, which do not grow linearly here).
- "10% match": all entities have C0, 10% also C1, the rest C0+C2 or C0+C3. Sparse set drives from the smallest
  participating dense array (1k entities), archetype skips the two non-matching tables.
- Churn adds a `Toggle` tag (or an 8-byte payload) to every entity on one frame and removes it on the next;
  entities carry four other components. Per operation: sparse 12 ns, block 10 ns, archetype 115 ns.
- Fragmentation: C0, C1 and a different subset of 16 tag types per entity (1,024 distinct sets). Sparse set is
  unaffected; archetype visits 1,024 tables with about ten rows each.
- Packs (D7 fallback, 8 to 20 reads) are 20 to 40x slower than per-arity code on sparse set (145 to 363 ns per
  entity) and 4 to 14x on archetype. The optimizer lowers pack expansions to dynamic pack loops over
  metadata, which matches S1. The per-arity overloads must cover the common cases; the pack path is a correctness
  fallback only.
- **Allocations per entity during iteration: 0** for every storage and arity (1R, 4R, 1R1W, 20R pack, fragmented).
  Method: macOS only, `malloc_logger` hook installed through `dlsym` counts every libmalloc allocation; the gate is
  `S2Bench --allocations`, which measures in a clean process state. The in-table rows of the full run show one
  anomaly: ArchetypeStorage 1R reports about 38 allocations per pass (not per entity) in the full run only, in
  no isolated run, and not in the 4R/1R1W rows that use the same code path. It is not explained (see risks).

### BlockSparseSet (block-allocated dense array)

1,024-element blocks allocated by hand (`UnsafeMutablePointer<C>` per block, manual initialize/deinitialize, block
table reached through a hoisted pointer). It matches the `ContiguousArray` variant on reads, is 25 to 30% slower
on writes (extra indirection per element, no flat base pointer), 20% faster on churn (no array growth checks)
and 20% slower on random `get`. It has stable element addresses and never copies on growth, which the benchmarks
do not reward. **Not recommended**: no win that survives, more unsafe code (the conformance suite does cover
its leak/double-free behavior). Keep it out of M1 unless stable addresses become a requirement.

## Protocol shape and trade-offs

`NexusStorageProviding: AnyObject` has no associated types. Typed operations are generic methods; the per-arity
iteration overloads (1R, 2R, 4R, 1R1W, 2R1W) and the pack fallback are protocol requirements taking a
`FamilyFilter` (extra required / excluded component masks). The client is meant to be generic over the
conformer, `Nexus<Storage: NexusStorageProviding>`, with `Nexus.init(storage: .default)` resolving through a
static member on `extension NexusStorageProviding where Self == SparseSetStorage`.

Why not an existential (`any NexusStorageProviding`): every call becomes an existential dispatch plus an
unspecialized generic call. That costs per call, not per entity (the entity loop lives inside the conformer),
but it also blocks inlining of the typed fast paths, which turned out to be the dominant performance factor:

- Making typed `set`/`get`/`modify`/`remove` and the iteration loops `@inlinable` (so they specialize in the
  client) cut sparse-set random `get` from 311 to 111 us and churn from 1650 to 1090 us.
- Generic classes dispatch their virtual methods unspecialized: a swap-remove through the class's
  `override func remove` cost 90 ns, the same body inlined into the typed call costs 12 ns. Anything per entity
  must be reachable as `@inlinable` generic code, not through a vtable of a generic class. The untyped paths
  (`remove(componentIndex:)`, `anyComponent`, `assign(any:)`) deliberately stay virtual and slow.
- Dynamic exclusivity enforcement on class-stored arrays cost 8x on random `get` (110 to 13 us) and 4x on churn.
  The storage state is marked `@exclusivity(unchecked)` and protected by the D4 lock instead
  (`lockDepth`; structural change during a scoped access or iteration traps; covered by exit tests).

Trade-offs of the generic design: `Nexus` becomes generic (type names get longer; a typealias for the default
helps), the client module needs `@inlinable` bodies and `@usableFromInline` state (more public surface to
keep stable), and storages cannot be swapped at runtime. The alternative that keeps `Nexus` non-generic is an
existential stored once, with per-arity iteration entered through a single existential call: it costs one
dynamic dispatch per forEach and the per-call setup is not inlined, but the entity loop stays specialized if the
loops live in the conformer. That variant was not benchmarked; the generic variant is the recommended one.

## What carries into PR 5 (#134) and PR 13 (#142)

Unchanged:

- `NexusStorageProviding` requirements (typed set/get/modify/remove/has, untyped slow paths, filters,
  `withComponents`, per-arity iteration with a pack fallback), `ComponentMask`, `FamilyFilter`, `EntityTable`.
- `SparseSetStorage`, `ComponentStorage`, `PagedSparseIndex`, `AnyComponentStorage` (paged index, swap-remove,
  hoisted `SparseIndexView`).
- `ArchetypeStorage`, `ArchetypeTable`, `Column` (cached add/remove edges, row moves via `moveInitialize`).
- `Tests/S2StorageTests` (parameterized conformance suite, token-based leak checks, exit tests for D4 traps).

Needs rework:

- `EntityID` is a bare `UInt32` index: D5 (index + generation, PR 4) needs a generation check in `isAlive` and in
  every typed entry point; the sparse index stays keyed by `index`.
- `Component.componentIndex` is a hand-assigned static (as in S1). The real assignment (macro, registry) is
  open; the storage layer only needs a dense, stable `Int` below `ComponentMask.capacity` (256, a hard limit).
- Iteration arities beyond the five here (3R, 3R1W, 0R2W, ...) per D7 (0-4 reads x 0-4 writes) are mechanical
  copies; they should be generated, not hand-written.
- Archetype queries rescan all tables every call. A cached table list per `FamilyFilter` is the first fix for
  the fragmentation case.
- `BlockSparseSetStorage` is a benchmark artifact and does not carry.

## Risks and open items

- **Escaped base pointers.** Iteration takes `withUnsafeMutableBufferPointer { $0.baseAddress }` and keeps the
  pointer for the loop. That is formally undefined; it works because the lock guarantees the array is not touched
  and the buffer is made unique first. A storage that owns its memory (the block variant, the archetype `Column`)
  does not need the trick. PR 5 should move `ComponentStorage` to owned memory as `Column` already is.
- **`@exclusivity(unchecked)` correctness rests on the lock.** Replacing a value of a component that an
  enclosing `modify` closure currently holds is caught by `lockDepth`; reading it with `get` inside the closure
  is not (no trap, and with checks off, a silent aliasing read). Decide whether `get` inside `modify` must trap.
- **Archetype per-table overhead (1.0 us)** is retain/release and uniqueness traffic per table (sampled with
  `sample`: about 60% retain/release). Unmanaged column pointers cached per table are the likely fix; not tried.
- **Archetype 1R allocation anomaly** (about 38 allocations per pass in the full benchmark process only) is
  unexplained. It does not scale with entities, but the 2.0 gate says zero; re-check on CI before relying on it.
- **Dead-entity handling**: mutating operations trap, read operations report absence; with D5 generations this
  needs one consistent rule.
- **Single run, one machine, Swift 6.4.** Numbers are best-of-five-batches means without confidence intervals;
  the Swift 6.2 compiler (the package minimum) has not been run on any of this. Pack lowering and `unsafeAddress`
  specialization may differ.
- **Memory**: not measured. Sparse set pays 16 KiB per touched page per component type plus the id array;
  archetype pays one column array per table (1,024 tables x 2 columns here).
