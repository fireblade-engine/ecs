# Spike S2: storage for `Nexus`, sparse set vs archetype (decision D3)

Branch `spike/s2-storage`. Code: `Sources/S2Storage` (storages and the closed-enum `S2Nexus`, carries into M1),
`Tests/S2StorageTests` (conformance and safety suites, carries), `Sources/S2Bench` (spike only). Toolchain Swift
6.4 on an Apple M1 Max; Swift 6.2 evidence comes from CI. This is the round-2 report: it replaces the first one
(see git history, b6100b3) after an independent review, the user's decision for a non-generic `Nexus`, and the
Swift 6.2 CI failures on #132.

## Recommendation

**`.default` is the archetype storage** (`S2Nexus.StorageKind.default`), `.sparseSet` stays selectable for
churn-heavy worlds. This reverses the first round's recommendation; the reasons are corrected measurements, not
taste. Both storages ship; the choice is one enum case.

Corrected numbers (below), per entity unless stated:

| | sparse set | archetype |
| --- | ---: | ---: |
| family iteration, 2 to 4 reads | 1.6 to 2.7 ns | 0.2 to 0.4 ns |
| 1R1W / 2R1W | 1.3 / 1.8 ns | 0.24 / 0.33 ns |
| 100k entities, permuted dense order, 2 reads | 1.8 ns | 0.19 ns |
| 1,024 distinct component sets, 2 reads | 1.5 ns | 0.9 ns |
| add or remove one component | 10 ns | 113 ns |
| String-field component add or remove | 12 ns | 64 ns |
| random `get` | 2.0 ns | 2.7 ns |

Break-even: one component add/remove costs archetype about 100 ns more; it saves about 1.4 to 2.4 ns per entity
per iterated family. An entity that takes part in 20 family passes per frame saves about 40 ns, so archetype
stays ahead as long as an entity changes its component set less than about once every three frames. FSM state
changes and tags toggled on a few entities are far below that; toggling a tag on every entity every frame is
the only measured case where sparse set wins big (10x). Pack iteration (8 to 20 reads) is 18 to 7x faster on
archetype. The first round's claim that "sparse set has no bad case" was wrong: it is 7 to 19x behind on
packs and 6 to 10x behind on iteration of large or permuted families.

What archetype costs: churn (above), a 30% slower random `get`, memory per table, and more machinery to get
right (the query cache and unmanaged column pointers are the reason fragmentation went from 1026 us to 8.8 us,
and they are the code most worth a second review). If the user weighs predictable worst cases over throughput,
`.sparseSet` is the defensible default; nothing else in the design changes.

## Closed-enum `S2Nexus`

`S2Nexus` is a non-generic final class holding `enum Backend { case sparse(SparseSetStorage), archetype(ArchetypeStorage) }`
and created with `S2Nexus(storage: .default | .sparseSet | .archetype)`. Every typed call switches once and then
runs the storage's specialized code. Per-arity iteration (1R, 2R, 4R, 1R1W, 2R1W) and the pack fallback are
concrete `@inlinable` methods on each storage plus a forwarding method on `S2Nexus`; none is a protocol
requirement.

- Dispatch cost: 4-read iteration 27.4 us direct vs 27.3 us through `S2Nexus` (sparse), 4.03 vs 4.03 us
  (archetype); `get` +8% (18.5 to 20.0 us per 10k). The branch is not measurable per call.
- `NexusStorageProviding` is gone. With a closed set of two storages the protocol only duplicated the API, and
  its 24-requirement generic surface was the source of the Swift 6.2 Windows compiler crash (SILGenPack,
  protocol witness thunk for the pack `forEach`). The shared conformance suite now runs the same test bodies
  against `S2Nexus` for each `StorageKind`, which covers the enum dispatch too. No third-party storages.
- `BlockSparseSetStorage` is removed: it matched the array variant on reads, was 30% slower on writes and its
  only edge (stable addresses) is irrelevant once the plain sparse storage owns its memory too. Its round-1
  numbers are in b6100b3.

## Numbers

Microseconds per pass, 10k entities and all members unless stated; best of five batches, release build from
HEAD, through `S2Nexus`. Reductions xor the `Double` bit patterns: a floating-point accumulator in the bench
closure forced a 4-cycle loop-carried `fadd` that capped every row at about 9 us (round-1 flaw), the xor chain is
one cycle. A raw xor loop over 10k `UInt64` takes 0.79 us.

| case | sparse set | archetype |
| --- | ---: | ---: |
| iterate 1 read | 0.79 | 0.87 |
| iterate 2 reads | 16.1 | 2.12 |
| iterate 4 reads | 27.4 | 4.05 |
| iterate 1R1W | 13.0 | 2.39 |
| iterate 2R1W | 18.2 | 3.34 |
| iterate 8 reads, pack | 1454 | 80.9 |
| iterate 16 reads, pack | 2825 | 193 |
| iterate 20 reads, pack | 3624 | 541 |
| iterate 2 reads, 10% match | 2.63 | 0.20 |
| iterate 1R1W, 10% match | 2.37 | 0.21 |
| iterate 2 reads, excl. C2 | 3.43 | 0.20 |
| 100k entities, permuted dense order: 2 reads | 184 | 18.9 |
| 100k entities, permuted dense order: 1R1W | 171 | 22.3 |
| String component: iterate 1R1W | 14.3 | 5.10 |
| String component: add or remove on 10k, per frame | 120 | 637 |
| churn: toggle tag on 10k, per frame | 96.6 | 1132 |
| churn: toggle 8-byte payload on 10k, per frame | 97.1 | 1136 |
| churn: toggle tag on 1k, per frame | 9.60 | 110 |
| iterate 2 reads after churn | 15.8 | 1.89 |
| 1,024 component sets: iterate 2 reads | 15.3 | 8.76 |
| random `get` of C0, 10k lookups | 20.5 | 26.9 |
| 1,024 component sets: random `get` | 20.8 | 46.2 |

Notes:

- 1R on a sparse set is a dense scan with no lookups (equal to the raw loop). From 2 reads on, each extra
  component costs a paged sparse lookup per entity; with permuted dense arrays (100k entities) it is cache
  bound: 1.7 to 1.8 ns per entity against 0.19 on archetype.
- The packs (D7 fallback) are dynamic pack loops: 145 to 363 ns per entity on sparse set (an 8-read pack is 53x
  slower than the 4-read overload), 8 to 54 ns on archetype. Per-arity overloads must cover the common cases.
- Archetype fragmentation: the matching-table list is cached per family (extended only by tables created since
  the last call) and columns are read through unretained pointers. The same 1,024-table world went from 1026 us
  (rescan plus retain/release per table) to 8.76 us. A new family pays one scan of all tables on first use.
- Churn is a row move per column on archetype (`moveInitialize` of each column, edge-cached target table); the
  hand-managed column buffer is what brought it from 9.3 ms to 1.1 ms per frame in round 1.
- Random `get` regressed against round 1 (12.7/9.4 to 20.5/26.9 us) because of the new aliasing check
  (`requireReadable`), the aliveness check and the component-type check; it is the price of the safety rules.
- **Allocations per entity during iteration: 0**, all storages, all arities (1R, 4R, 1R1W, 20R pack,
  fragmented). Method: macOS only, a `malloc_logger` hook installed through `dlsym` counts libmalloc allocations
  made by the measuring thread; `S2Bench --allocations` is the clean-process gate; non-Darwin platforms skip it.
  The round-1 anomaly (archetype 1R at about 38 allocations per pass in the full run only) did not reproduce
  once the counter filtered to the measuring thread and counted minimum-of-seven trials; the hook now prints
  stacks for any nonzero count, and none printed. It was almost certainly other threads' allocations, but I
  did not capture the original to prove it.

## Safety rules implemented (review findings 1 to 3, 9, 10)

- Sparse-set dense arrays are owned memory (`ComponentStorage`, like `Column`); nothing is a pointer into a
  `withUnsafe…` scope, so nested `get`, `modify`, `withComponents` and iteration see real data (round 1 emptied
  the array under the closure). Test: `nestedAccessToTheSameTypeSeesRealData`.
- Writes are tracked per component type (`activeWrites` mask, separate from the structural lock). Trapping, with
  distinct messages and tests: nested write iteration or `modify` of one type, `get` or iteration of a type
  inside a write to it, reading and writing one type in one iteration. Reading the same type twice nested is
  allowed.
- Storages and columns record `ObjectIdentifier(C.self)`; every `unsafeDowncast` is guarded by a precondition,
  so two types sharing a `componentIndex` trap instead of reinterpreting memory. `ComponentMask.contains/remove`
  and the untyped paths are range checked (negative and 256+ report absence).
- Swap-remove moves the removed value out and releases it last, after ids, sparse index and buffer are
  consistent.
- Sparse-set `get` checks aliveness like the archetype does. With D5 generations this becomes one rule.

## CI (Swift 6.2) fixes

- Exit tests are compiled only on macOS, Linux and Windows (`#if os(macOS) || os(Linux) || os(Windows)`), and
  check the specific trap message through `observing: [\.standardErrorContent]`.
- `S2Bench` imports Darwin behind `#if canImport(Darwin)`; the allocation counter is macOS-only and says so.
- The pack `forEach` is no longer a protocol requirement, so no witness thunk is generated for it. That should
  remove the Windows SILGenPack crash; it is **not verified** (no 6.2 or Windows toolchain here). If it still
  crashes, guard the pack path with `#if compiler(>=6.3) || !os(Windows)`.

## What carries into PR 5 (#134) and PR 13 (#142)

Unchanged: `ComponentMask`, `FamilyFilter`, `EntityTable`, `PagedSparseIndex`, `ComponentStorage`,
`ArchetypeStorage`/`ArchetypeTable`/`Column`, `S2Nexus` as the shape of `Nexus`, both test suites.

Needs rework: `EntityID` generations (D5); `Component.componentIndex` assignment (hand-assigned static here,
256-component hard limit); the remaining arities of D7 (generate them); the query cache has no invalidation
beyond table creation (fine while tables are never removed); `withComponents` on the archetype yields one run
per table.

## Open risks

- Archetype default rests on iteration-heavy workloads. A world that changes component sets of most entities
  every frame (115 ns per change, 1.1 ms per 10k) is better on `.sparseSet`; there is no runtime switch.
- `@exclusivity(unchecked)` state and the unmanaged table and column pointers are sound only because tables and
  columns are never removed and every structural change is blocked while a scope is open; any future table
  removal or compaction must revisit both.
- Windows SILGenPack fix and every Swift 6.2 result are unverified; numbers are single-machine, single-run.
- Random `get` is 30 to 100% slower than round 1 because of the safety checks; the fragmented archetype `get`
  (46 us per 10k) is the slowest read path.
- Memory is still not measured (16 KiB sparse page per touched page and type; archetype one column per table).
