# ``FirebladeECS``

A lightweight, fast and easy to use Entity-Component System in Swift.

## Overview

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. 
An ECS comprises entities composed from components of data, with systems which operate on the components.

Fireblade ECS is available for all platforms that support [Swift 6.1](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).
It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

The optional `FirebladeECSMacros` product adds the `@Component` macro, which depends on [swift-syntax](https://github.com/swiftlang/swift-syntax). The core `FirebladeECS` library has no dependencies.

For a more detailed example of FirebladeECS in action, see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).

## Topics

### Essentials

- <doc:GettingStartedWithFirebladeECS>
- <doc:ComponentMacro>
- ``Nexus``
- ``NexusEvent``
- ``NexusEventDelegate``

### Entities

- ``Entity``
- ``EntityState``
- ``EntityStateMachine``
- ``EntityCreated``
- ``EntityDestroyed``
- ``EntityComponentHash``
- ``EntityIdentifier``
- ``EntityIdentifierGenerator``
- ``DefaultEntityIdGenerator``
- ``LinearIncrementingEntityIdGenerator``

### Components

- ``Component``
- ``ComponentAdded``
- ``ComponentRemoved``
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
- ``FamilyMemberContainer``
- ``Single``

### Coding Strategies

- ``CodingStrategy``
- ``DefaultCodingStrategy``
- ``TopLevelDecoder``
- ``TopLevelEncoder``
- ``DynamicCodingKey``

### Supporting Types

- ``ManagedContiguousArray``
- ``UnorderedSparseSet``

### Hash Functions

- ``hash(combine:)``
- ``hash(combine:_:)``
- ``StringHashing``
