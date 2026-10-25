# ``FirebladeECS``

A lightweight, fast and easy to use Entity-Component System in Swift.

## Overview

FirebladeECS is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) in Swift.
An ECS comprises entities composed from components of data, with systems which operate on the components.
It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

Components are value types, structs or enums. Reading a component returns a copy; you change one with ``Entity/set(_:)-(Component)``, ``Entity/modify(_:_:)`` or, for many entities at once, ``Family/forEach(reading:writing:_:)``. Entity identifiers carry a generation, so a destroyed entity never matches a later one that reuses its slot. A ``Nexus`` stores components in an archetype storage by default, or in a sparse set, see <doc:ChoosingAStorage>.

```swift
struct Position: Component { var x = 0.0, y = 0.0 }
struct Velocity: Component { var dx = 0.0, dy = 0.0 }

let nexus = Nexus()
nexus.createEntity {
    Position()
    Velocity(dx: 1)
}

let movers = nexus.family(requiresAll: Position.self, Velocity.self)
movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
}
```

FirebladeECS requires Swift 6.2 or later and ships three products:

- `FirebladeECS` is the core library and has no dependencies.
- `FirebladeECSMacros` adds the `@Component` and `@FamilyTraits` macros and depends on [swift-syntax](https://github.com/swiftlang/swift-syntax). It does not re-export `FirebladeECS`: import both modules.
- `FirebladeFSM` adds entity state machines, see the FirebladeFSM documentation. Import it next to `FirebladeECS`.

Upgrading from 1.x? Start with <doc:MigratingToFirebladeECS2>. For a more detailed example of FirebladeECS in action, see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).

## Topics

### Essentials

- <doc:GettingStartedWithFirebladeECS>
- <doc:ReadingAndWritingComponents>
- <doc:ComponentMacro>
- <doc:ReactingToNexusEvents>
- <doc:ChoosingAStorage>
- <doc:SavingAndLoadingScenes>
- <doc:MigratingToFirebladeECS2>
- ``Nexus``
- ``NexusEvent``
- ``NexusEventDelegate``
- ``NexusEventMask``
- ``Nexus/StorageKind``

### Entities

- ``Entity``
- ``EntityCreated``
- ``EntityDestroyed``
- ``EntityComponentHash``
- ``EntityIdentifier``
- ``EntityIdentifierGenerator``
- ``PersistableEntityIdentifierGenerator``
- ``DefaultEntityIdGenerator``
- ``LinearIncrementingEntityIdGenerator``

### Components

- ``Component``
- ``ComponentAdded``
- ``ComponentRemoved``
- ``ComponentReplaced``
- ``ComponentModified``
- ``ComponentsModified``
- ``ComponentsBuilder-4co42``
- ``ComponentsBuilder``
- ``ComponentIdentifier``
- ``ComponentInitializable``
- ``ComponentTypeHash``
- ``SingleComponent``
- ``DefaultInitializable``

### Component Registry

- ``RegistrableComponent``
- ``StableComponentIdentifier``
- ``ComponentTypeRecord``
- ``ComponentRegistryError``

### Cloning

- ``CloneableComponent``
- ``ComponentCloneContext``
- ``ComponentCloneError``

### Snapshots

- ``SerializableComponent``
- ``NexusSnapshot``
- ``NonSerializableComponentHandling``
- ``ComponentSerializationError``
- ``EntityReferenceResolver``
- ``EntityReferenceError``

### Inspection

- ``InspectableComponent``
- ``ComponentProperty``
- ``InspectedComponentProperty``

### Systems

- ``Family``
- ``FamilyMemberAdded``
- ``FamilyMemberRemoved``
- ``FamilyTraitSet``
- ``FamilyProtocol``
- ``FamilyTraitsProviding``
- ``FamilyMemberContainer``
- ``Single``

### Coding Strategies

- ``CodingStrategy``
- ``DefaultCodingStrategy``
- ``TopLevelDecoder``
- ``TopLevelEncoder``
- ``DynamicCodingKey``

### Supporting Types

- ``UnorderedSparseSet``

### Hash Functions

- ``hash(combine:)``
- ``hash(combine:_:)``
- ``StringHashing``
