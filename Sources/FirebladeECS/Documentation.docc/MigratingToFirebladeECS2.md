# Migrating to FirebladeECS 2

Update code for the changes in FirebladeECS 2.

## Overview

FirebladeECS 2 is a breaking release. This article lists the changes of the entity identifiers, one section per change.

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
