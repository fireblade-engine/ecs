# Reading and writing components

Read a copy, replace a component or change it in place.

## Overview

Three operations cover everything you do with the components of an ``Entity``:

| Intent | Call | Result |
| :-- | :-- | :-- |
| Read a copy | ``Entity/get(_:)`` | `C?`, `nil` if missing |
| Replace or add | ``Entity/set(_:)-(Component)`` | the entity, for chaining |
| Change in place | ``Entity/modify(_:_:)`` | `Bool`, `false` if missing |

```swift
let position: Position? = entity.get(Position.self)       // a copy
entity.set(Position(x: 0, y: 0))                          // adds, or replaces the existing one
entity.modify(Position.self) { $0.x += 1 }                // changes the stored component, false if missing
entity.modify(Counter.self, default: Counter()) { $0.value += 1 }   // adds the default first if missing
entity.remove(Position.self)                              // false if the entity had none
```

Subscripts offer the same operations:

```swift
entity[Position.self]?.x += 1                             // in place, nothing happens if missing
entity[Counter.self, default: Counter()].value += 1       // adds the default when mutating
let counter = entity[Counter.self, default: Counter()]    // reading never adds anything
entity[\Position.x] = 3                                   // WritableKeyPath, adds a default Position if missing
```

``Entity/modify(_:default:_:)`` and the `default:` subscript evaluate the default only when the component is missing.
Like `Dictionary.subscript(_:default:)`, reading never inserts and mutating does.

Change several components with ``Entity/components(_:writing:_:)``. The read components arrive as copies, the written ones as `inout`. Overloads exist for 0 to 4 read and 0 to 4 written types, and a parameter pack overload covers more:

```swift
entity.components(Position.self, writing: Velocity.self) { position, velocity in
    velocity.dx += position.x
}
```

### Iterating a family and writing

``Family/forEach(reading:writing:_:)`` visits every member of a family, hands out the read components as copies and the written ones as `inout`, and writes them into the storage in place. It is the fast way to update many entities: it resolves the typed storages once and runs a plain loop, with no allocation per member.

```swift
let movers = nexus.family(requiresAll: Position.self, Velocity.self)
movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
}
```

Overloads exist for 0 to 4 read and 0 to 4 written types. A parameter pack overload covers more; its closure takes the written components first, as one `inout` tuple, and copies them back after each call. Every type must be a required component of the family. The access labels follow the `in` and `inout` access modifiers of flecs queries, see Prior art below.

While the closure runs the nexus is locked like in ``Entity/modify(_:_:)``: structural changes (creating or destroying entities, adding or removing components, replacing a component with `set`) stop the process with a message, as do reading a written type through the nexus, writing a type twice and nesting a write of a written type. Collect structural changes and apply them after the call. A delegate subscribed to ``NexusEventMask/valueChanges`` receives one ``ComponentsModified`` per written type and call, not one event per member.

### Copies and the var hazard

`get` returns a copy. For a value type component, `var health = entity.get(Health.self)!; health.hp -= 10` changes the copy and nothing else.
Write it back with `set`, or change the component in place with `modify`. Components declared with `@Component` are classes until the macro supports structs. A copy of a class component still refers to the stored instance and the change is visible, but write code as if it were a value type.

Iterating a family hands out copies as well. `for var position in family { position.x += 1 }` compiles and changes nothing. Write through the entity inside the loop, for example with ``Entity/modify(_:_:)`` or ``Entity/set(_:)-(Component)``.

### Rules for code that runs while a component is changed

A `modify` closure (and the in place access of a subscript, ``Entity/components(_:writing:_:)`` or ``Family/forEach(reading:writing:_:)``) runs while the nexus holds the component. In there:

- Adding or removing components, creating or destroying entities of the same nexus stops the process with a message.
- Reading or modifying the same component type again stops the process with a message.
- Other component types can be read.

Mutating a destroyed entity returns `false` (or does nothing) and fails an assertion in debug builds. ``Entity/modify(_:default:_:)`` never inserts a component into a destroyed entity.

### Events

- ``Entity/set(_:)-(Component)`` delivers ``ComponentAdded`` for a new component and ``ComponentReplaced`` when it replaces one.
- ``Entity/modify(_:_:)`` and in place subscript access deliver ``ComponentModified``. Adding a missing default delivers ``ComponentAdded`` first.
- ``Family/forEach(reading:writing:_:)`` delivers one ``ComponentsModified`` per written type after the pass.
- ``ComponentReplaced`` and ``ComponentModified`` reach only delegates subscribed to ``NexusEventMask/valueChanges``.

### Entity lifetime

An ``Entity`` holds its ``Nexus`` unowned and unchecked, so copying it costs no reference counting. It must not outlive its nexus.

### Declaring a family as a type

With the optional `FirebladeECSMacros` product, `@FamilyTraits` declares a family once, with its access, and binds it to any nexus:

```swift
@FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
struct Movers {}

let movers = Movers(in: nexus)
movers.forEach { velocity, position in position.x += velocity.dx }
let previewMovers = Movers(in: previewNexus) // same declaration, another world
```

`Movers` has two roles. The type is the static declaration: ``FamilyTraitsProviding/traits``, ``FamilyTraitsProviding/readComponents`` and ``FamilyTraitsProviding/writeComponents`` need no nexus, so a scheduler can tell which systems conflict. A `Movers` value is that family bound to one nexus. Binding is a lookup in a per type cache of the nexus by ``FamilyTraitsProviding/familyIndex``, not a trait set hash, so create the value once and keep it in the system. Like an ``Entity``, it must not outlive its nexus.

The generated `forEach` takes the read components first, then the written ones as `inout`, and calls the matching ``Family/forEach(reading:writing:_:)`` overload (the parameter pack fallback above 4 reads or 4 writes). Reading and writing the same type, an empty declaration, arguments that are not metatypes (`Position.self`) and attaching the macro to anything but a struct are compile time errors.

The macro is sugar: conform to ``FamilyTraitsProviding`` by hand to get the same without swift-syntax, and ``Nexus/family(requiresAll:excludesAll:)`` keeps working.

### Prior art

The API follows the flecs entity API:

- `ecs_set` replaces the component and fires `OnSet`: ``Entity/set(_:)-(Component)``.
- `ecs_ensure` returns the component and creates it if missing: ``Entity/modify(_:default:_:)``.
- `ecs_get_mut` returns `NULL` if the component is missing: ``Entity/modify(_:_:)`` returns `false`, the optional subscript does nothing.
- `query.each([](Position& p, const Velocity& v) {})` takes `const` references for reads and references for writes, and query terms carry the `in` and `inout` access modifiers ("Access modifiers" in the [flecs queries manual](https://github.com/SanderMertens/flecs/blob/master/docs/Queries.md)): ``Family/forEach(reading:writing:_:)`` states the same access with the `reading:` and `writing:` labels.
- `flecs::entity` stores a raw `world_t*` and does not keep the world alive: `Entity` holds its nexus `unowned(unsafe)`.
- A flecs query is built once, bound to a world and iterated many times (`world.query_builder<Position, const Velocity>().without<Frozen>().build()`), with `in` and `inout` access per term: `@FamilyTraits` declares the terms once and binds them to a nexus with ``FamilyTraitsProviding``.
- Bevy's `Query<(&Velocity, &mut Position), Without<Frozen>>` is a system parameter whose read and write sets the scheduler uses to run non conflicting systems in parallel: ``FamilyTraitsProviding/readComponents`` and ``FamilyTraitsProviding/writeComponents`` expose the same sets statically.
