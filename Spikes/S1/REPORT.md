# Spike S1: family API with parameter packs (D7)

Toolchain: Swift 6.4 (Xcode 27) locally. Swift 6.2 compile evidence is pending CI (the spike targets are part of
`make build-debug` / `make test`). SIL: `Spikes/S1/check-sil.sh` (-O, WMO, concrete call sites in `CallSites.swift`).
Timing: `make build-release && .build/release/S1Bench`.

## Verdict

- Plain packs express the family API only partly. **`repeat inout each W` closure parameters do not work**
  (see below). What works: writes as one `inout (repeat each W)` tuple (**variant A**) or as trailing
  `repeat Mut<each W>` handles (**variant Mut**).
- Both variants: zero heap allocations, zero existentials, zero key paths in SIL. **Neither meets the
  "zero witness_method" gate**: the pack loops stay dynamic in -O SIL (`dynamic_pack_index`, per element generic
  calls on `@pack_element` archetypes), and the generic `World.storage<C>` is called unspecialized
  (`witness_method C.componentIndex`). `@inline(__always)` on the helpers makes it worse (16 to 32 witness calls).
- Cost: 1R1W over 10k entities, -O: A 211 us, Mut 199 us, 1.x `Family` iterator 1178 us, hand-written loop on the
  same storage 7.9 us (first measurement, see Gap attribution). Packs are about 6x faster than 1.x but about 25x slower than a concrete loop.
- **`Mut<W>` is not needed** for correctness and not better: same SIL counts, same speed, and its safety features
  (`~Copyable`, `~Escapable`) cannot be combined with packs on 6.4. `_modify value` is not needed either: the
  `@dynamicMemberLookup` subscript leaves no key path in SIL (`site_MutValue` equals `site_Mut`).
- Closures taking `Mut<W>` crash Swift 6.2 assert compilers (Windows 6.2.0+Asserts, WASM 6.2.1) in SILGen: `Assertion failed: (isLoadableOrOpaque(LV->getType())), function createLoad`; Mut tests are removed and the bench call sites are guarded with `#if compiler(>=6.3)`.

## Recommended D7 shape

```swift
public struct Reading<each R: Component> { public init(_: repeat (each R).Type) }
public struct Writing<each W: Component> { public init(_: repeat (each W).Type) }
public struct Family<Read, Write> { ... }   // two packs in one type are rejected, so wrap each pack

extension Family {
    public func forEach<each R: Component, each W: Component>(
        _ body: (inout (repeat each W), repeat each R) -> Void
    ) where Read == Reading<repeat each R>, Write == Writing<repeat each W>
}
// family.forEach { (w: inout (Vel, Hp), p: Pos, v: Vel2) in w.0.x = p.x }
```

Writes come first because a pack may only trail in a callable function type (see pain points). Alternatives that
compile: reads as one tuple then `inout` write tuple (`((repeat each R), inout (repeat each W))`, call site
`{ (r: (Pos, Vel), w: inout (Hp, Tag)) in }`; hit a SIL crash in my implementation, see below), and
`((repeat each R), repeat Mut<each W>)`. Because hot loops stay generic, the final design should also keep the door
open to macro-generated per-arity overloads (prior art: `@Family`, `#familyEach`) if the 2.0 perf budget needs
specialized code; that is a decision for D7, not settled here.

## Variant x arity

Compiles on 6.4: yes everywhere below (tests pass). 6.2: pending CI. Counts are for the call site plus every
S1 function it reaches (cold `createStorage` excluded, stdlib excluded).

| Site | alloc_ref | alloc_box | existential | witness_method | keypath | allocObject | dyn. access | pack loop idx |
| :--- | --: | --: | --: | --: | --: | --: | --: | --: |
| A 1R1W | 0 | 0 | 0 | 4 | 0 | 0 | 6 | 10 |
| A 2R2W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 20 |
| A 1R3W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 23 |
| A 4R0W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 20 |
| A 0R4W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 20 |
| Mut 1R1W | 0 | 0 | 0 | 4 | 0 | 0 | 6 | 9 |
| Mut 2R2W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 18 |
| Mut 1R3W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 20 |
| Mut 0R4W | 0 | 0 | 0 | 4 | 0 | 0 | 10 | 20 |
| Mut `value` 1R1W | 0 | 0 | 0 | 4 | 0 | 0 | 6 | 9 |
| Entity per step 1R1W | 0 | 0 | 0 | 4 | 0 | 0 | 4 | 3 |

Notes: the 4 witness_method calls are all in the unspecialized `World.storage<C>`. "dyn. access" are `begin_access
[dynamic]` on class properties of the storages; `S1_SWIFTC_FLAGS=-enforce-exclusivity=unchecked` removes them (0).
Mut 4R0W is not applicable (no writes). Mut with `~Copyable` or `~Escapable` is not expressible (below), so the
shipped Mut is a plain pointer wrapper and can escape its step.

## Type-inference and language pain points (exact errors, 6.4)

1. `repeat inout each W` as closure parameter: type `(repeat inout each W) -> Void` parses, but calling it
   (`body(repeat &(each w).pointee)`) gives `'&' may only be used to pass an argument to inout parameter`, and
   `body(repeat (each w).pointee)` **crashes the compiler** (signal 5 in SILGen, `emitPackExpansionIntoPack`). A
   closure written against it gets `let` parameters: `left side of mutating operator isn't mutable: 'p' is a 'let'
   constant`. `(inout repeat each W)` does not parse (`expected type`).
2. Two packs in one closure type cannot be inferred: `generic parameter 'each R' could not be inferred` and
   `cannot convert value of type '(P, Mut<V>, Mut<H>) -> ()' to expected argument type '(repeat each R, repeat Mut<each W>)'`.
3. A function value whose type is `(repeat each R, X)` cannot be called: `missing argument for parameter #2 in call`
   plus `cannot pass value pack expansion to non-pack parameter of type 'repeat each R'`. `(X, repeat each R)` and
   `((repeat each R), X)` work. Hence writes first (or reads as a tuple).
4. Two packs in a generic type: `generic type cannot declare more than one type pack`. Wrappers
   `Reading<each R>`/`Writing<each W>` plus `where Read == Reading<repeat each R>` work.
5. `Mut<C>: ~Copyable` in a pack closure: `parameter of noncopyable type 'repeat Mut<each W>' must specify
   ownership`; `repeat borrowing Mut<each W>` is not accepted either. `~Escapable` Mut: `lifetime-dependent value
   escapes its scope` when constructing it in the pack expansion.
6. SILGen crash (6.4, -Onone and -O): binding the read tuple (`let r = (repeat load(each rp))`) and then passing it
   as a single tuple argument next to a pack or `inout` tuple. Passing the tuple expression inline, or `repeat each r`
   flat, works. Variant "reads tuple + inout tuple" hit this; not retried inline.
7. Tuples can be expanded with `each` (`each rs` over a `let` tuple of a pack type); non-pack tuples (e.g. `(repeat Int)`
   indices) cannot: `'each' cannot be applied to non-pack type 'Int'`.
8. `Mut.value` shadows a component field named `value` (`h.value` resolves to the accessor, not `Hp.value`).
9. Type-checker time: six pack-based call sites in one function took more than 120 s; the same calls type-check
   instantly one per function.
10. The `ComponentStorage<C>` mutable base pointer comes from `withUnsafeMutableBufferPointer` and is only valid while
   no structural change happens during iteration (spike simplification).

## Deep dive: non-escapable Entity (`Sources/S1EntityView`, own target with `Lifetimes`)

| Item | Result |
| :--- | :--- |
| `world.entity(_:)` returning `~Escapable Entity` with `@_lifetime(borrow self)` | compiles, works |
| Escape is rejected | yes: `a function with a ~Escapable result needs a parameter to depend on` |
| Closure fallback `withEntity(id) { (e: borrowing EntityScope) in }` without the feature (`~Copyable` scope, in `S1FamilyAPI`) | compiles, works |
| `Equatable` | compiles (`==` takes `borrowing`); `#expect(a == b)` does not (Testing macro needs Escapable), use a local `let` |
| `Hashable` | compiles |
| `Equatable`/`Hashable` on Swift 6.2 | **fails**: `type 'Entity' does not conform to protocol 'Escapable'`; both conformances (and their tests) are guarded with `#if compiler(>=6.3)`, they need a toolchain newer than 6.2 |
| `CustomStringConvertible` | **fails**: `type 'Entity' does not conform to protocol 'Escapable'` (plain `description` property works) |
| `forEachEntity { (e: Entity) in }` per step | compiles, 0 alloc_ref/alloc_box/allocObject in SIL |

## Span availability (D4), platform minimums macOS 14 / iOS 17, typechecked with -target macos14.0 / ios17.0

| API | Without `@available` |
| :--- | :--- |
| `ContiguousArray.span`, `.mutableSpan` | compiles (macOS 14, iOS 17) |
| `Array.span` | needs `@available(macOS 26, iOS 26, *)` |
| `Span(_unsafeElements:)`, `MutableSpan(_unsafeElements:)` from `withUnsafe(Mutable)BufferPointer` | compiles |
| `UnsafeBufferPointer.span`, `UnsafeMutableBufferPointer.mutableSpan` | compiles |
| `Span.count/indices/withUnsafeBufferPointer`, `borrowing Span<T>` parameters | compiles |
| Functions returning `Span`/`RawSpan` (`~Escapable` result) | need `@_lifetime` and `Lifetimes`: `a function cannot return a ~Escapable result` |

Caveat: result from the Swift 6.4 toolchain with the macOS 27 SDK; re-check on 6.2/Xcode 26 in CI before relying on
`ContiguousArray.span` ungated. Decision stands: span APIs stay availability-gated.

## Gap attribution (1R1W, 10k entities, -O, us per pass)

`S1_UNCHECKED=1 make build-release` builds the S1 targets with `-enforce-exclusivity=unchecked` (unsafeFlags in the spike
targets only). "Per-arity" is `World.forEach<R, W>(reading:writing:_:)` in `Concrete.swift`: same World, storages,
smallest-set walk and sparse lookups, no packs. The "hand-written" loop already did the sparse lookup per entity, but
walked the position storage directly and held concrete storages (no `World.storage` lookups, no smallest-set choice).

| Loop | exclusivity checked | unchecked |
| :--- | --: | --: |
| Variant A (packs) | 211 | 117 |
| Variant Mut (packs) | 199 | 106 |
| Per-arity overload, no packs | 14.6 | 12.5 |
| Hand-written concrete loop (sparse lookups) | 7.9 | 7.9 |
| 1.x `Family` iterator | 1178 | 1165 (not S1) |

The 4 `witness_method` calls run once per `forEach` (prologue: `World.storage` for the driver search and the
`rs`/`ws` tuples), not per entity. Per entity the pack loops call the generic `fetchElement`/`loadElement`/`storeElement`
with pack-element archetypes (unspecialized generic calls, no witness lookups), plus dynamic exclusivity checks.

Conclusion: of the ~25x gap, the pack machinery is about 8 to 9x over the equivalent per-arity code (117 vs 12.5 unchecked),
exclusivity checks add another ~1.8x on top for packs, and the iteration architecture (storage lookup, smallest-set
walk) costs only ~1.6x over the concrete loop (12.5 vs 7.9). Per-arity overloads (macro or generated) would keep
nearly all of the speed, so the D7 trade-off is packs (ergonomics, ~10x slower than per-arity) vs generated arities.

## Open items

- Swift 6.2 compile of all four spike targets pending CI (incl. `Lifetimes` and the `Equatable`/`Hashable` on `~Escapable`).
- Performance gap vs concrete loops (25x) needs a D7 decision (macro/arity overloads vs accepting packs).
- Not measured: package-benchmark (skipped on purpose; plain `ContinuousClock` loop in `S1Bench`).
