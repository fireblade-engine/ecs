# ``FirebladeFSM``

Entity state machines that add and remove components when an entity changes state.

## Overview

`FirebladeFSM` is an optional product of the FirebladeECS package. The core `FirebladeECS` library does not depend on it.

Define an ``EntityState`` for each state an entity can be in and map the components of that state to component providers.
An ``EntityStateMachine`` then swaps the components of the old state for the components of the new state when you call ``EntityStateMachine/changeState(name:)``.

Add the product to your target and import both modules:

```swift
.target(name: "YourTarget",
        dependencies: [
            .product(name: "FirebladeECS", package: "ecs"),
            .product(name: "FirebladeFSM", package: "ecs")
        ])
```

```swift
import FirebladeECS
import FirebladeFSM

let nexus = Nexus()
let entity = nexus.createEntity()
let machine = EntityStateMachine<String>(entity: entity)
machine.createState(name: "idle").addType(Position.self)
machine.createState(name: "moving").addType(Position.self).addType(Velocity.self)
machine.changeState(name: "moving")
```

## Topics

### States

- ``EntityStateMachine``
- ``EntityState``
- ``StateComponentMapping``

### Component providers

- ``ComponentProvider``
- ``ComponentTypeProvider``
- ``ComponentInstanceProvider``
- ``ComponentSingletonProvider``
- ``DynamicComponentProvider``
