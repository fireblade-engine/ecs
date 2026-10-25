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

Change several components with ``Entity/components(_:_:writing:_:_:)-(_,_,_,_,_)``. The read components arrive as copies, the written ones as `inout`:

```swift
entity.components(Position.self, writing: Velocity.self) { position, velocity in
    velocity.dx += position.x
}
```

### Copies and the var hazard

`get` returns a copy. For a value type component, `var health = entity.get(Health.self)!; health.hp -= 10` changes the copy and nothing else.
Write it back with `set`, or change the component in place with `modify`. While components are classes, the copy still refers to the stored instance and the change is visible, but write code as if it were a value type.

### Rules for code that runs while a component is changed

A `modify` closure (and the in place access of a subscript or ``Entity/components(_:_:writing:_:_:)-(_,_,_,_,_)``) runs while the nexus holds the component. In there:

- Adding or removing components, creating or destroying entities of the same nexus stops the process with a message.
- Reading or modifying the same component type again stops the process with a message.
- Other component types can be read.

Mutating a destroyed entity returns `false` (or does nothing) and fails an assertion in debug builds. ``Entity/modify(_:default:_:)`` never inserts a component into a destroyed entity.

### Events

- ``Entity/set(_:)-(Component)`` delivers ``ComponentAdded`` for a new component and ``ComponentReplaced`` when it replaces one.
- ``Entity/modify(_:_:)`` and in place subscript access deliver ``ComponentModified``. Adding a missing default delivers ``ComponentAdded`` first.
- ``ComponentReplaced`` and ``ComponentModified`` reach only delegates subscribed to ``NexusEventMask/valueChanges``.

### Entity lifetime

An ``Entity`` holds its ``Nexus`` unowned and unchecked, so copying it costs no reference counting. It must not outlive its nexus.

### Prior art

The API follows the flecs entity API:

- `ecs_set` replaces the component and fires `OnSet`: ``Entity/set(_:)-(Component)``.
- `ecs_ensure` returns the component and creates it if missing: ``Entity/modify(_:default:_:)``.
- `ecs_get_mut` returns `NULL` if the component is missing: ``Entity/modify(_:_:)`` returns `false`, the optional subscript does nothing.
- `flecs::entity` stores a raw `world_t*` and does not keep the world alive: `Entity` holds its nexus `unowned(unsafe)`.
