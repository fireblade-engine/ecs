# Migrating to FirebladeECS 2

Update code for the changes in FirebladeECS 2.

## Overview

FirebladeECS 2 is a breaking release. This article lists the changes, one section per change.

### Entity identifiers carry a generation

An ``EntityIdentifier`` is now a 64 bit value: the slot index in the low 32 bits and the slot generation in the high 32 bits.
Destroying an entity bumps the generation of its slot, so the identifier of a destroyed entity never matches a later entity that reuses the slot.

- ``EntityIdentifier/invalid`` is now the raw value `0`, not `UInt32.max`. The slot index 0 is never handed out, and generations start at 0.
- `EntityIdentifier` is no longer `ExpressibleByIntegerLiteral`, and it is no longer `RawRepresentable`. Code that built identifiers from integers needs ``EntityIdentifier/init(index:generation:)``:

```swift
// before
let id: EntityIdentifier = 42
let same = EntityIdentifier(42)

// after
let id = EntityIdentifier(index: 42, generation: 0)
```

  Use ``EntityIdentifier/rawValue`` and ``EntityIdentifier/init(rawValue:)`` only for snapshots and networking.
- `EntityIdentifier.id` is deprecated in favor of ``EntityIdentifier/index``, which is a `UInt32` now (it was an `Int`).
  `EntityIdentifier.Identifier` is deprecated in favor of ``EntityIdentifier/Index``.
- ``EntityIdentifier/isValid`` tells the invalid identifier from the others.

### Check identifiers before using them

Keep ``Entity`` values or identifiers of entities that may be destroyed, and check them before use:

```swift
if let entity = nexus.entity(savedIdentifier) {
    entity.set(Position(x: 0, y: 0))
}
nexus.isAlive(savedIdentifier)
```

- ``Nexus/entity(_:)`` returns `nil` for stale identifiers. It replaces `entity(from:)`, which is deprecated and does not check.
- ``Nexus/isAlive(_:)`` replaces `exists(entity:)`.
- Changing a destroyed entity returns `false` (or does nothing for chained calls like `Entity.set(_:)`) and stops with an assertion in debug builds. The message names both versions, for example `stale handle 7v3, slot is at 7v4`.
- A slot whose generation reaches `UInt32.max` is retired and never handed out again; the generation never wraps around.

### Custom entity identifier generators

``EntityIdentifierGenerator`` hands out the generations now. ``EntityIdentifierGenerator/markUnused(entityId:)`` receives the identifier of the destroyed entity, and the generator provides its slot again with a higher generation, or retires it.
Generators must never provide the same identifier twice or an identifier with index 0.
Generators conforming to ``PersistableEntityIdentifierGenerator`` must persist the generations of the slots they recycle.

### Snapshots

``NexusSnapshot/formatVersion`` is 3. Snapshots of format versions 1 and 2 still load, see <doc:SavingAndLoadingScenes>.
Component properties of type ``EntityIdentifier`` are encoded as 64 bit raw values now.

### Component storage

A ``Nexus`` keeps its components in a storage chosen at creation, ``Nexus/init(storage:)``. ``Nexus/StorageKind/sparseSet`` is the only storage so far and the default, so `Nexus()` works as before.
There is no storage protocol: the set of storages is closed, so each storage compiles to concrete code.

- Components are stored per type in one dense array with a paged sparse index, and each entity holds a bitset of its component types. Adding, removing and looking up a component touches one type's data only.
- Every component type has a dense ``Component/componentIndex``. Plain conformances get it lazily, in order of first use and shared by all nexuses of the process. There is no limit on the number of component types.
- Public API that returned or took component storage internals is unchanged. ``ManagedContiguousArray`` is no longer used by ``Nexus``; it stays available until it is removed.
- The components an entity iterates, and the components of a snapshot or clone, come in ``Component/componentIndex`` order now instead of hash order.

### Events

- ``NexusEventDelegate`` has a new requirement ``NexusEventDelegate/subscribedEvents`` with a default implementation returning ``NexusEventMask/structural``. Existing delegates compile and receive the same events as before.
- Return ``NexusEventMask/valueChanges`` (or ``NexusEventMask/all``) to opt in to ``ComponentReplaced``, ``ComponentModified`` and ``ComponentsModified``. The nexus reads the mask when the delegate is assigned, so assign the delegate again after changing it.
- ``NexusEvent`` is an open protocol and new events can appear in any release. Add a `default:` case to every `switch` over events.
- Structural events are always delivered, whatever the mask says.

See <doc:ReactingToNexusEvents>.

### Entity API

The entity API separates reading a copy, replacing and changing in place, see <doc:ReadingAndWritingComponents>.

- ``Entity/remove(_:)-(ComponentIdentifier)`` and its siblings return `Bool` (discardable): `true` if a component was removed, `false` if the entity had none or is destroyed. They returned the entity for chaining before, so a chain like `entity.remove(A.self).remove(B.self)` no longer compiles. Remove one component per statement.
- ``Entity/set(_:)-(Component)`` replaces a component the entity already has. It kept the existing component and reported a non-fatal error to the delegate before. Delegates subscribed to ``NexusEventMask/valueChanges`` receive ``ComponentReplaced``. The deprecated `assign` methods and `Nexus.assign` replace as well.
- Removing a component the entity does not have delivers no ``ComponentRemoved`` event any more.
- ``Entity/modify(_:_:)`` and ``Entity/modify(_:default:_:)`` change a component in place. The entity subscripts `entity[Position.self]?.x += 1` and `entity[Counter.self, default: Counter()].value += 1` do the same.
- The key path subscripts and ``Entity/set(value:for:)-(_,WritableKeyPath<Comp,Value>)`` take `WritableKeyPath` and change the stored component in place. That works for value types, not only for classes (the 1.x implementation wrote to a copy, which only worked because components were classes).
- ``Entity/components(_:_:writing:_:_:)-(_,_,_,_,_)`` and its siblings change several components at once.
- ``Entity`` holds its ``Nexus`` as `unowned(unsafe)`: copying an entity costs no reference counting, but using an entity after its nexus was deallocated is undefined behavior. Keep the nexus alive as long as you use its entities. It was a checked `unowned` reference before, which trapped.
- While a `modify` closure or an in place subscript access runs, adding or removing components or entities of the same nexus, and reading or modifying the same component type, stop the process with a message such as `structural change while a scoped access is running`. Do such changes after the closure.
