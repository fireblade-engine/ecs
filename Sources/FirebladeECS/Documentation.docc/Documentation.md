# ``FirebladeECS``

A lightweight, fast and easy to use Entity-Component System in Swift.

## Overview

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. 
An ECS comprises entities composed from components of data, with systems which operate on the components.

Fireblade ECS is available for all platforms that support [Swift 6.2](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).
It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

The optional `FirebladeECSMacros` product adds the `@Component` macro, which depends on [swift-syntax](https://github.com/swiftlang/swift-syntax). The core `FirebladeECS` library has no dependencies.

For a more detailed example of FirebladeECS in action, see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).

## Topics

### Essentials

- <doc:GettingStartedWithFirebladeECS>
- <doc:ComponentMacro>
- <doc:SavingAndLoadingScenes>
- <doc:ReactingToNexusEvents>
- <doc:ReadingAndWritingComponents>
- <doc:ChoosingAStorage>
- <doc:MigratingToFirebladeECS2>
- ``Nexus``
- ``NexusEvent``
- ``NexusEventDelegate``
- ``NexusEventMask``
- ``Nexus/StorageKind``

### Entities

- ``Entity``
- ``EntityState``
- ``EntityStateMachine``
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
- ``ComponentProvider``
- ``ComponentsBuilder-4co42``
- ``ComponentsBuilder``
- ``ComponentInstanceProvider``
- ``ComponentIdentifier``
- ``ComponentInitializable``
- ``ComponentTypeHash``
- ``ComponentTypeProvider``
- ``ComponentSingletonProvider``
- ``SingleComponent``
- ``StateComponentMapping``
- ``DynamicComponentProvider``
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
