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
- ``Entity/components(_:writing:_:)`` and its siblings (0 to 4 read and 0 to 4 written types) change several components at once.
- ``Family/forEach(reading:writing:_:)`` updates the components of all family members in place and is much faster than iterating the family: `movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in position.x += velocity.dx }`.
- ``FamilyTraitsProviding`` and the `@FamilyTraits` macro (new, optional) declare a family as a type and bind it to a nexus: `@FamilyTraits(reading: Velocity.self, writing: Position.self) struct Movers {}`, then `Movers(in: nexus).forEach { velocity, position in ... }`.
- ``Entity`` holds its ``Nexus`` as `unowned(unsafe)`: copying an entity costs no reference counting, but using an entity after its nexus was deallocated is undefined behavior. Keep the nexus alive as long as you use its entities. It was a checked `unowned` reference before, which trapped.
- While a `modify` closure or an in place subscript access runs, adding or removing components or entities of the same nexus, and reading or modifying the same component type, stop the process with a message such as `structural change while a scoped access is running`. Do such changes after the closure.

### Components are value types

``Component`` no longer requires `AnyObject`. Declare components as structs or enums; classes still work, but the nexus stores them like any other value. A component with a handle that is not `Sendable` conforms with `@unchecked Sendable`. The `@Component` macro still only accepts classes until a later release.

```swift
// before
final class Position: Component { var x = 0, y = 0 }

// after
struct Position: Component { var x = 0, y = 0 }
```

- Reading a component (`get`, `entity[Position.self]`, family iteration) returns a copy. Changing the copy does not change the stored component. Write with ``Entity/set(_:)-(Component)``, ``Entity/modify(_:_:)``, the entity subscripts or the key path subscripts.
- Iteration hands out copies. `for var position in family { position.x += 1 }` compiles and silently changes nothing. Use `family.forEach(writing: Position.self) { $0.x += 1 }`, or `family.entities` and `entity.modify(Position.self) { $0.x += 1 }`, or `entityAndComponents` and `entity.set(...)`.
- Identity is gone. `===` between components, `ObjectIdentifier(component)` and `weak` or `unowned` references to a component do not compile for structs. Compare values (make the struct `Equatable`) and keep an ``Entity`` or ``EntityIdentifier`` to refer to a component.
- Two entities no longer share a component instance: `set(sameValue)` on two entities stores two independent copies. Snapshots therefore never write `sharedComponents` any more; they are still read from format versions 1 and 2, each entity gets its own copy.
- ``ComponentProperty/isWritable`` is true for every `WritableKeyPath`, not only for `ReferenceWritableKeyPath`.
- A component keeps its stored properties alive for as long as the nexus stores it. If a property is a class instance, `deinit` runs when the last copy is released.

### Single

``Single/component`` returns a copy and is read-only. `single.component.value = x` no longer compiles for a struct component (it wrote to the shared instance before). Use the new write methods:

```swift
single.modify { $0.value = x }       // in place, delivers ComponentModified
single.set(GameState(value: x))      // replaces the component, delivers ComponentReplaced
```

### State machine providers

``ComponentProvider/getComponent()`` returns a component value that the machine stores through ``Entity/set(_:)-(Component)``.

- ``ComponentSingletonProvider`` creates its value on first use and hands a copy of it to every entity. It used to hand the same instance to every entity, so a change through one entity was visible on all. Now each entity owns its copy. The name is kept for source compatibility; ComponentValueProvider would describe it better and may replace it.
- Values have no identity, so a provider is identified by the provider object: ``ComponentInstanceProvider/identifier`` and ``ComponentSingletonProvider/identifier`` are unique per provider. When an entity changes state, a component stays only if both states share the same provider object (`withProvider(_:)`). Two ``ComponentInstanceProvider``s holding equal values are different providers and the component is removed and added again.
