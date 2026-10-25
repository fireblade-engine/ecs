# Migrating to FirebladeECS 2

Move a project from FirebladeECS 1.x to 2.0: components become value types, and every write goes through the nexus.

## Overview

In FirebladeECS 2 components are value types. You write them as structs, reading one returns a copy, and every write goes through `set`, `modify` or a `writing:` closure. Entity identifiers carry a generation, so a destroyed entity never matches a later one. The state machine and the macros are separate products.

Most projects migrate in three moves: fix the 1.x deprecation warnings, turn component classes into structs, and replace the writes that relied on reference semantics. One of those writes is invisible to the compiler: read [the `for var` hazard](#The-for-var-hazard) before you start.

### Before you start

Work in this order. Every step builds on its own, so you can commit after each one.

1. Update to the final 1.x release and fix every deprecation warning. Each has a fix-it, for example `assign` becomes ``Entity/set(_:)-(Component)``.
2. Raise the toolchain to Swift 6.2 or later.
3. Change the dependency to `from: "2.0.0"`. Add the `FirebladeFSM` product if you use the state machine, and `FirebladeECSMacros` if you use `@Component` or `@FamilyTraits`.
4. Turn component classes into structs. The compiler now flags the code that relied on reference semantics.
5. Replace those writes with `set`, `modify` or `forEach(reading:writing:)`.
6. Search for the pattern the compiler cannot catch: `var` copies of components, and `for var` over families.
7. Walk through the [checklist](#Checklist).

### Quick reference

| FirebladeECS 1.x | FirebladeECS 2.x | Notes |
| :-- | :-- | :-- |
| `final class Position: Component` | `struct Position: Component`, or `@Component struct Position` | The macro rejects classes. A hand-written class conformance asserts once per type in debug builds. |
| `entity.assign(c)`, `nexus.assign(component:to:)` | `entity.set(c)` | `assign` stays deprecated. `set` now replaces an existing component. |
| `entity.get(component: C.self)?.x = 1` | `entity.modify(C.self) { $0.x = 1 }` or `entity[C.self]?.x = 1` | `get` returns a copy. |
| `entity[\C.x] = v` | same spelling | The key path is a `WritableKeyPath` now, not a `ReferenceWritableKeyPath`. |
| `nexus.get(safe:)`, `nexus.get(unsafe:)` | `nexus.entity(id)?.get(C.self)` | Removed. |
| `entity.remove(C.self)` returning the entity | same call returning `Bool` | Discardable, but chains no longer compile. |
| not available | `entity.modify(C.self, default: C()) { ... }`, `entity[C.self, default: C()]` | Adds the default if the component is missing. |
| `for (pos, vel) in family { pos.x += vel.dx }` | `family.forEach(reading: Velocity.self, writing: Position.self) { vel, pos in pos.x += vel.dx }` | Plain iteration yields copies. |
| `single.component.value = x` | `single.modify { $0.value = x }` or `single.set(_:)` | `component` is a read-only copy. |
| `struct Link: Component { let target: Entity }` | `... let target: EntityIdentifier` | `@Component` reports a stored `Entity` with a fix-it. |
| `EntityIdentifier(42)`, `42` as a literal | `EntityIdentifier(index: 42, generation: 0)` | 64 bit: index and generation. |
| `nexus.entity(from: id)`, `nexus.exists(entity: id)` | `nexus.entity(id)`, `nexus.isAlive(id)` | Stale identifiers return `nil` and `false`. |
| `import FirebladeECS` for `EntityStateMachine` | `import FirebladeFSM` next to `import FirebladeECS` | Separate product. |
| `import FirebladeECSMacros` alone | `import FirebladeECS` and `import FirebladeECSMacros` | The macros no longer re-export the library. |
| `ComponentSingletonProvider` | same provider | Hands each entity its own copy of one value. |
| `NexusEventDelegate` | same, plus `subscribedEvents` | Value change events are opt in. |
| `ManagedContiguousArray` | removed | Copy the 1.x file if you use it directly. |

### Components

Components are structs or enums, and they are `Sendable`. Replace the class, and the reference to the parent by an identifier:

```swift
// before
final class Transform: Component, @unchecked Sendable {
    var position: SIMD3<Float> = .zero
    var parent: Entity?
}

// after
struct Transform: Component {
    var position: SIMD3<Float> = .zero
    var parent: EntityIdentifier?
}
```

- ``Component`` no longer requires `AnyObject`. The nexus stores every component by value; a class conformance still compiles, but it asserts once per type in debug builds, and the `@Component` macro rejects it with an error.
- `Sendable` is automatic when all stored properties are `Sendable`. A component with a handle that is not (a Metal object, for example) conforms with `@unchecked Sendable`.
- Store an ``EntityIdentifier``, not an ``Entity``. An entity handle is not valid after a clone or a snapshot, and a stored handle cannot tell that the entity is gone. Resolve the identifier with ``Nexus/entity(_:)``, which returns `nil` for a destroyed entity. With the macro, a stored `Entity` (also optional, array, set or dictionary value) is an error with a fix-it that replaces it.
- With `@Component`, a struct whose stored properties all have defaults gets `init()` (``DefaultInitializable``), and keeps its memberwise initializer. See <doc:ComponentMacro>.
- ``CloneableComponent``, ``SerializableComponent`` and ``InspectableComponent`` are unchanged. The ``ComponentCloneContext`` remaps ``EntityIdentifier`` properties.
- Identity is gone. `===`, `ObjectIdentifier(component)` and `weak` or `unowned` references to a component do not compile for structs. Make the struct `Equatable` to compare values, and keep an ``EntityIdentifier`` to refer to a component.
- Two entities no longer share a component instance: `set(sameValue)` on two entities stores two independent copies. Snapshots therefore never write `sharedComponents` any more; format versions 1 and 2 still load, and each entity gets its own copy.
- ``ComponentProperty/isWritable`` is true for every `WritableKeyPath`, not only for `ReferenceWritableKeyPath`. ``ComponentProperty/set(_:on:)`` writes an inspected property of a component copy.
- If a property is a class instance, its `deinit` runs when the last copy of the component is released.

### Reading and writing components

In 1.x `get` returned the component itself, so a change to it changed the stored component. In 2.x it returns a copy. Three operations cover reading and writing, see <doc:ReadingAndWritingComponents>:

```swift
entity.modify(Health.self) { $0.hp -= 10 }          // in place; false if the entity has no Health
entity[Health.self]?.hp -= 10                       // the same through the subscript
entity[\Health.hp] = 50                             // WritableKeyPath, adds a default Health if missing
entity.set(Health(hp: 100))                         // adds, or replaces an existing Health
entity.modify(Health.self, default: Health(hp: 100)) { $0.hp -= 10 }   // adds the default first if missing
```

``Entity/modify(_:_:)`` returns `false` if the entity does not have the component (the result is discardable). Reading `entity[Health.self, default: Health(hp: 100)]` never inserts; only writing does, like `Dictionary.subscript(_:default:)`. The key path subscripts need a ``DefaultInitializable`` component. Assigning through one adds a default component if missing; reading through one (also the read half of `-=`) requires the component to exist.

``Entity/set(_:)-(Component)`` replaces a component the entity already has. In 1.x it kept the existing one and reported a non-fatal error to the delegate. Delegates subscribed to ``NexusEventMask/valueChanges`` receive ``ComponentReplaced``.

``Entity/remove(_:)-(ComponentIdentifier)`` and its siblings return `Bool`, `true` if a component was removed. A chain like `entity.remove(A.self).remove(B.self)` no longer compiles; remove one component per statement. Removing a component the entity does not have delivers no ``ComponentRemoved`` event any more.

Change several components at once with ``Entity/components(_:writing:_:)``, with 0 to 4 read and 0 to 4 written types.

#### The for var hazard

The compiler catches `entity.get(component: Health.self)?.hp -= 10`, because `get` returns an rvalue. It does not catch these, and they silently change nothing:

```swift
// Compiles, runs, and does not change the stored component.
var health = entity.get(Health.self)!
health.hp -= 10

// Compiles, runs, and does not change any stored component.
for (var position, velocity) in family {
    position.x += velocity.dx
}
```

Both change a copy. Search your code for `var` bindings of components and for `for (var` and `for var` over families, and replace each one:

```swift
// write the copy back
var health = entity.get(Health.self)!
health.hp -= 10
entity.set(health)

// or change the component in place
entity.modify(Health.self) { $0.hp -= 10 }

// and update many entities in place
family.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
}
```

A grep like `grep -rnE "for \(?var |= .*\.get\(" Sources` finds the candidates. Tests that read a component back after a system ran are the other safety net.

### Families

Creating a family is unchanged: ``Nexus/family(requiresAll:excludesAll:)``. Plain iteration, ``Family/entities`` and ``Family/entityAndComponents`` yield read-only copies, so a read-only system can keep its `for` loop. Writers move to ``Family/forEach(reading:writing:_:)``, which hands out the read components as copies and the written ones as `inout` and updates the storage in place, with no allocation per member:

```swift
let movers = nexus.family(requiresAll: Position.self, Velocity.self)
movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
}
```

- Every type must be a required component of the family. Optional components in a query are not supported.
- Overloads exist for 0 to 4 read and 0 to 4 written types, reads first. A parameter pack overload covers more: its closure takes the written components first, as one `inout` tuple.
- Structural changes inside the closure (creating or destroying entities, adding, removing or replacing components) stop the process with a message. Collect them and apply them after the call.
- Unchanged: ``Family/count``, ``Family/isEmpty``, ``Family/isMember(_:)``, ``Family/canBecomeMember(_:)``, ``Family/createMember(with:)`` and ``Family/destroyMembers()``.
- New and optional: with the `FirebladeECSMacros` product, `@FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self) struct Movers {}` declares a family as a type, and `Movers(in: nexus).forEach { velocity, position in ... }` runs it. Conform to ``FamilyTraitsProviding`` by hand to get the same without swift-syntax.
- New: ``Nexus/componentSpan(reading:_:)``, ``Nexus/componentSpan(writing:_:)`` and ``Family/forEachComponentSpan(reading:writing:_:)`` hand out components as a `Span` or `MutableSpan` inside a closure. Nothing to migrate; they are available on macOS 26, iOS 26, tvOS 26, watchOS 26 and visionOS 26, so guard the calls with `if #available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)`. See <doc:ReadingAndWritingComponents>.

### Entity identifiers

An ``EntityIdentifier`` is a 64 bit value: the slot index in the low 32 bits and the slot generation in the high 32 bits. Destroying an entity bumps the generation of its slot, so the identifier of a destroyed entity never matches a later entity that reuses the slot.

- ``EntityIdentifier/invalid`` is the raw value `0` (it was `UInt32.max`). The slot index 0 is never handed out, and generations start at 0.
- `EntityIdentifier` is no longer `ExpressibleByIntegerLiteral` and no longer `RawRepresentable`. Code that built identifiers from integers needs ``EntityIdentifier/init(index:generation:)``. Use ``EntityIdentifier/rawValue`` and ``EntityIdentifier/init(rawValue:)`` (now `UInt64`) only for snapshots and networking.
- `EntityIdentifier.id` is deprecated in favor of ``EntityIdentifier/index``, and `EntityIdentifier.Identifier` in favor of ``EntityIdentifier/Index``. Both are `UInt32`. ``EntityIdentifier/isValid`` tells the invalid identifier from the others.

```swift
// before
let id: EntityIdentifier = 42

// after
let id = EntityIdentifier(index: 42, generation: 0)
```

Check identifiers that may be stale before you use them:

```swift
if let entity = nexus.entity(savedIdentifier) {
    entity.set(Position(x: 0, y: 0))
}
let stillThere = nexus.isAlive(savedIdentifier)
```

- ``Nexus/entity(_:)`` returns `nil` for stale identifiers. It replaces `entity(from:)`, which is deprecated and does not check. ``Nexus/isAlive(_:)`` replaces `exists(entity:)`.
- Changing a destroyed entity returns `false` (or does nothing for chained calls like ``Entity/set(_:)-(Component)``) and stops with an assertion in debug builds. The message names both versions, for example `stale handle 7v3, slot is at 7v4`.
- A slot whose generation reaches `UInt32.max` is retired and never handed out again.
- ``EntityIdentifierGenerator`` hands out the generations now. ``EntityIdentifierGenerator/markUnused(entityId:)`` receives the identifier of the destroyed entity, and the generator provides the slot again with a higher generation, or retires it. A generator must never provide the same identifier twice or an identifier with index 0. A ``PersistableEntityIdentifierGenerator`` must persist the generations of the slots it recycles.
- ``NexusSnapshot/formatVersion`` is 3 and component properties of type ``EntityIdentifier`` are encoded as 64 bit raw values. Snapshots of format versions 1 and 2 still load, with generation 0, see <doc:SavingAndLoadingScenes>.
- An ``Entity`` handle works as before. It holds its ``Nexus`` as `unowned(unsafe)`: copying costs no reference counting, and using an entity after its nexus was deallocated is undefined behavior (it trapped before). Keep the nexus alive as long as you use its entities.

### Single

``Single/component`` returns a copy and is read-only. `single.component.value = x` no longer compiles for a struct component. Use the write methods:

```swift
let settings = nexus.single(Settings.self)
settings.modify { $0.volume = 0.8 }         // in place, delivers ComponentModified
settings.set(Settings(volume: 0.8))         // replaces the component, delivers ComponentReplaced
```

### The state machine

The state machine moved out of `FirebladeECS` into the optional `FirebladeFSM` product, like the macros in `FirebladeECSMacros`. The code is unchanged and the type names are the same. Add the product and import it next to `FirebladeECS` in every file that uses `EntityStateMachine`, `EntityState`, `StateComponentMapping` or a component provider:

```swift
// Package.swift
.target(name: "YourTarget",
        dependencies: [
            .product(name: "FirebladeECS", package: "ecs"),
            .product(name: "FirebladeFSM", package: "ecs")
        ])
```

```swift
import FirebladeECS
import FirebladeFSM
```

``DefaultInitializable`` and ``ComponentInitializable`` stay in `FirebladeECS`, because the entity subscripts use them.

`ComponentProvider.getComponent()` returns a component value that the machine stores through ``Entity/set(_:)-(Component)``.

- `ComponentSingletonProvider` creates its value on first use and hands a copy of it to every entity. It used to hand the same instance to every entity, so a change through one entity was visible on all. Now each entity owns its copy. State that must be shared belongs in a ``Single``. The name is kept for source compatibility.
- Values have no identity, so a provider is identified by the provider object. When an entity changes state, a component stays only if both states share the same provider object (`withProvider(_:)`). Two `ComponentInstanceProvider`s holding equal values are different providers, and the component is removed and added again.

### Events

All structural events of 1.x are kept and always delivered. New: ``ComponentReplaced``, ``ComponentModified`` and the bulk ``ComponentsModified``, delivered only to delegates that opt in through the new requirement ``NexusEventDelegate/subscribedEvents``. Its default is ``NexusEventMask/structural``, so existing delegates compile and receive what they received before.

```swift
final class Observer: NexusEventDelegate {
    var subscribedEvents: NexusEventMask { .all }
    func nexusEvent(_ event: NexusEvent) {
        switch event {
        case let modified as ComponentModified:
            print("modified", modified.component)
        default:
            break
        }
    }
    func nexusNonFatalError(_ message: String) {}
}
```

- ``NexusEvent`` is an open protocol and new events can appear in any release. Add a `default:` case to every `switch` over events.
- The nexus reads the mask when the delegate is assigned, so assign the delegate again after changing it.

See <doc:ReactingToNexusEvents>.

### Storage

A ``Nexus`` keeps its components in a storage chosen at creation, ``Nexus/init(storage:)``. `Nexus()` uses the archetype storage. Pass `Nexus(storage: .sparseSet)`, the storage of 1.x, for workloads dominated by heavy add and remove churn. The API and its observable behavior are the same, except for iteration order, which is not a contract. The components an entity iterates, and the components of a snapshot or clone, come in ``Component/componentIndex`` order now instead of hash order. See <doc:ChoosingAStorage>.

`ManagedContiguousArray`, the container of the 1.x storage, is removed. Use ``UnorderedSparseSet`` or a Swift `ContiguousArray`.

### Imports and removed API

- `FirebladeECSMacros` no longer re-exports `FirebladeECS`. Add `import FirebladeECS` next to `import FirebladeECSMacros` in every file that uses library types.
- `Nexus.get(safe:for:)`, `Nexus.get(unsafe:for:)`, `Nexus.get(safe:)` and `Nexus.get(unsafe:)` are removed. Resolve the entity with ``Nexus/entity(_:)`` and read with ``Entity/get(_:)``.

```swift
// before
import FirebladeECSMacros
let position: Position? = nexus.get(safe: entityId)

// after
import FirebladeECS
import FirebladeECSMacros
let position = nexus.entity(entityId)?.get(Position.self)
```

### Checklist

- [ ] The last 1.x release builds without deprecation warnings.
- [ ] The toolchain is Swift 6.2 or later, the dependency is `from: "2.0.0"`, and `FirebladeFSM` is added where needed.
- [ ] Every file imports `FirebladeECS`; `FirebladeECSMacros` is imported only where `@Component` or `@FamilyTraits` is used.
- [ ] Every component is a struct or an enum.
- [ ] Components store ``EntityIdentifier``, not ``Entity``.
- [ ] Every write through `get` is replaced by `modify`, `set` or a subscript.
- [ ] No `var` copy of a component is expected to change the stored one, and no `for var` or `for (var` over a family remains.
- [ ] Systems that write use `forEach(reading:writing:)`.
- [ ] Writes through `single.component` are replaced.
- [ ] Hard-coded identifiers and custom ``EntityIdentifierGenerator``s are updated.
- [ ] Users of `ComponentSingletonProvider` expect one copy per entity.
- [ ] Event `switch` statements have a `default:` case.
- [ ] Saved 1.x snapshots load.
