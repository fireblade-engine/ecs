# Choosing a storage

Pick the sparse-set or the archetype storage for a ``Nexus``, and know what changes.

## Overview

A ``Nexus`` keeps its entities and components in one of two storages, chosen when it is created:

```swift
let nexus = Nexus(storage: .archetype)   // or .sparseSet
```

Both storages offer the same API with the same observable behavior: generational entity identifiers, events, the structural lock and its traps, families, `forEach(reading:writing:)`, spans, snapshots, cloning and the entity state machine. Every test of the package runs against both. What differs is where the components live in memory, and with it what is cheap.

``Nexus/StorageKind/default`` is ``Nexus/StorageKind/sparseSet`` for now. There is no storage protocol: the set of storages is closed, and a nexus switches on its storage once per call, so each storage compiles to concrete code.

### The sparse-set storage

``Nexus/StorageKind/sparseSet`` keeps one dense array per component type, a paged sparse index per type that maps an entity to its slot in that array, and a bitset of component types per entity. Adding or removing a component touches the data of that one type only, and no other component moves. Looking up one component is a sparse index read plus an array read.

Iterating a family is the weak spot: the members of a family are stored in each component array in the order the components were added, so every extra component type costs a lookup per member, and the reads are scattered once the arrays were shuffled by churn.

### The archetype storage

``Nexus/StorageKind/archetype`` follows the design of [flecs](https://www.flecs.dev/flecs/md_docs_2Queries.html): entities with exactly the same component types live in one table, with a column (an array) per component type. An index maps every entity to its table and row. Tables are created when a component set appears first, and adding or removing one component type moves the entity's row to another table along a cached edge of the table graph.

Iterating a family visits the tables that match it, and walks their columns linearly: no lookup per member and a sequential read per component. The list of matching tables is cached per family, which the nexus lists when the family is created and extends when a new table appears. A table that became empty stays alive, along with its columns and its entry in the cached lists, where an iteration skips it. Cleaning the nexus with ``Nexus/clear()`` drops all tables.

In flecs this is the default, and sparse components are the opt-in trait (`Sparse`): "Sparse components are stored outside of tables, which means they do not have to be moved", trading query speed for component add and remove speed (see [component traits](https://github.com/SanderMertens/flecs/blob/master/docs/ComponentTraits.md)). Fireblade 1.x was the reverse, a sparse set per component type; the two storages make that a choice per nexus instead of per component.

### What the numbers say

Measured with 10 000 entities, release build, Apple silicon, wall clock p50 per pass (`make benchmark`, see `Benchmarks/`):

| Case | Sparse set | Archetype |
| :-- | --: | --: |
| `forEach(reading: A)` | 11 μs | 2.5 μs |
| `forEach(reading: A, B)` | 18 μs | 4.3 μs |
| `forEach(reading: A, B, C, D)` | 31 μs | 7.7 μs |
| `forEach(reading: A, writing: B)` | 17 μs | 4.4 μs |
| `forEach(reading: A, B, writing: C)` | 23 μs | 6.1 μs |
| 2 reads, 10% of the entities match | 3.6 μs | 1.3 μs |
| 2 reads, 100 000 entities with shuffled storage order | 227 μs | 27 μs |
| 2 reads, 1 024 different component sets | 18 μs | 11 μs |
| Parameter pack, 5 reads and 2 writes | 2 200 μs | 1 800 μs |
| Plain `for` over a family, 2 components | 455 μs | 455 μs |
| Random `entity.get` of one component, 10 000 lookups | 334 μs | 345 μs |
| Add a component to each entity and remove it again, 10 000 entities | 2 180 μs | 4 900 μs |
| Create and destroy 1 000 entities with 7 components | 1 730 μs | 2 510 μs |

Fireblade 1.x needed 480 μs for the plain iteration of one component and 1 220 μs for two (`IterOnlyOneComponent`, `IterOnlyTwoComponents`). Both storages iterate without any allocation.

- Iterating with `forEach(reading:writing:)` is 1.6 to 8 times faster on the archetype storage: about 4 times in the plain case, 8 times when the sparse-set arrays are shuffled against each other, and least when the entities are spread over many small tables.
- Changing the component set of an entity costs about twice as much on the archetype storage: the whole row moves. An entity that changes its component set less than once in a few frames is far ahead on iteration; a world that toggles a component on most entities every frame is better off with the sparse set.
- Plain `for` iteration and random access cost the same on both: they look every component up per entity.
- Entity creation and destruction are a bit slower on the archetype storage, because the row of every component moves with the entity.

### Differences you can observe

- **Iteration order.** The sparse-set storage visits the members of a family in the order of the family's member list, the archetype storage table by table and row by row, and rows move when entities change tables. Neither order is a contract; use ``Entity/identifier`` or your own key if you need one.
- **Single-type spans.** ``Nexus/componentSpan(reading:_:)`` and ``Nexus/componentSpan(writing:_:)`` view one contiguous array. On the archetype storage a type is stored in one column per table, so if entities with different component sets have the type, the span views a temporary copy made table by table (and the writing variant stores it back when the closure returns, also when it throws). That costs one allocation and a copy per call, and nothing can observe the difference while the closure runs, because the type is locked.
- **Family spans.** ``Family/forEachComponentSpan(reading:writing:_:)`` passes one batch per matching table on the archetype storage, however the nexus was used before; the sparse-set storage passes shorter batches after churn. Both visit every member exactly once, and the closure must be correct for any batch size.

See <doc:ReadingAndWritingComponents> for the spans.
