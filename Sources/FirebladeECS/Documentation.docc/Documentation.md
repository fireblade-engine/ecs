# ``FirebladeECS``

Seamlessly, consistently, and asynchronously replicate data.

## Overview

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. 
An ECS comprises entities composed from components of data, with systems which operate on the components.

Fireblade ECS is available for all platforms that support [Swift 5.8](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).
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
- ``RequiringComponents1``
- ``RequiringComponents2``
- ``RequiringComponents3``
- ``RequiringComponents4``
- ``RequiringComponents5``
- ``RequiringComponents6``
- ``RequiringComponents7``
- ``RequiringComponents8``
- ``DefaultInitializable``
- ``SingleComponent``

### Systems

- ``Family``
- ``FamilyEncoding``
- ``FamilyDecoding``
- ``FamilyMemberAdded``
- ``FamilyMemberRemoved``
- ``FamilyMemberBuilder-3f2i6``
- ``FamilyMemberBuilder``
- ``FamilyTraitSet``
- ``Requires1``
- ``Requires2``
- ``Requires3``
- ``Requires4``
- ``Requires5``
- ``Requires6``
- ``Requires7``
- ``Requires8``
- ``Single``
- ``Family1``
- ``Family2``
- ``Family3``
- ``Family4``
- ``Family5``
- ``Family6``
- ``Family7``
- ``Family8``
- ``FamilyRequirementsManaging``

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
