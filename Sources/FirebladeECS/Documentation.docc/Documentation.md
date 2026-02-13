# ``FirebladeECS``

Seamlessly, consistently, and asynchronously replicate data.

## Overview

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. 
An ECS comprises entities composed from components of data, with systems which operate on the components.

Fireblade ECS is available for all platforms that support [Swift 6.1](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).
It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

For a more detailed example of FirebladeECS in action, see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).

## Topics

### Essentials

- <doc:GettingStartedWithFirebladeECS>
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
- ``EntityComponentHash``
- ``StateComponentMapping``
- ``DynamicComponentProvider``
- ``DefaultInitializable``
- ``SingleComponent``

### Systems

- ``Family``
- ``FamilyMemberAdded``
- ``FamilyMemberRemoved``
- ``FamilyTraitSet``
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
