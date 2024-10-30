# Getting started with Fireblade ECS

Learn the API and key types Fireblade provides to compose your game or app logic. 

## Overview

Fireblade ECS is a dependency free, Swift language implementation of an Entity-Component-System ([ECS](https://en.wikipedia.org/wiki/Entity_component_system)).
An ECS comprises entities composed from components of data, with systems which operate on the components.

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "0.17.5")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: ["FirebladeECS"])
    ]
)

```

This article introduces you to the key concepts of Fireblade ECS's API. 
For a more detailed example, see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).

### 🏛️ Nexus

The core element in the Fireblade-ECS is the [Nexus](https://en.wiktionary.org/wiki/nexus#Noun). 
It acts as a centralized way to store, access and manage entities and their components. 
A single `Nexus` may (theoretically) hold up to 4294967295 `Entities` at a time.   
You may use more than one `Nexus` at a time.

Initialize a `Nexus` with

```swift
let nexus = Nexus()
```

### 👤 Entities

then create entities by letting the `Nexus` generate them.

```swift
// an entity without components
let newEntity = nexus.createEntity()
```

To define components, conform your class to the `Component` protocol

```swift
final class Position: Component {
    var x: Int = 0
    var y: Int = 0
}
```
and assign instances of it to an `Entity` with

```swift
let position = Position(x: 1, y: 2)
entity.assign(position)
```

You can be more efficient by assigning components while creating an entity.

```swift
// an entity with two components assigned.
nexus.createEntity {
    Position(x: 1, y: 2)
    Color(.red)
}

// bulk create entities with multiple components assigned.
nexus.createEntities(count: 100) { _ in
    Position()
    Color()
}

```
### 👪 Families

This ECS uses a grouping approach for entities with the same component types to optimize cache locality and ease up access to them.   
Entities with the __same component types__ may belong to one `Family`. 
A `Family` has entities as members and component types as family traits.

Create a family by calling `.family` with a set of traits on the nexus.
A family that contains only entities with a `Movement` and `PlayerInput` component, but no `Texture` component is created by

```swift
let family = nexus.family(requiresAll: Movement.self, PlayerInput.self,
                          excludesAll: Texture.self)
```

These entities are cached in the nexus for efficient access and iteration.
Families conform to the [Sequence](https://developer.apple.com/documentation/swift/sequence) protocol so that members (components) 
may be iterated and accessed like any other sequence in Swift.   
Access a family's components directly on the family instance. To get family entities and access components at the same time call `family.entityAndComponents`.
If you are only interested in a family's entities call `family.entities`.

```swift
class PlayerMovementSystem {
    let family = nexus.family(requiresAll: Movement.self, PlayerInput.self,
                              excludesAll: Texture.self)

    func update() {
        family
            .forEach { (mov: Movement, input: PlayerInput) in
            
            // position & velocity component for the current entity
            
            // get properties
            _ = mov.position
            _ = mov.velocity
            
            // set properties
            mov.position.x = mov.position.x + 3.0
            ...
            
            // current input command for the given entity
            _ = input.command
            ...
            
        }
    }

    func update2() {
        family
            .entityAndComponents
            .forEach { (entity: Entity, mov: Movement, input: PlayerInput) in
            
            // the current entity instance
            _ = entity

            // position & velocity component for the current entity
            
            // get properties
            _ = mov.position
            _ = mov.velocity
            
            
        }
    }

    func update3() {
        family
            .entities
            .forEach { (entity: Entity) in
            
            // the current entity instance
            _ = entity
        }
    }
}
```

### 🧑 Singles

A `Single` on the other hand is a special kind of family that holds exactly **one** entity with exactly **one** component for the entire lifetime of the Nexus. This may come in handy if you have components that have a [Singleton](https://en.wikipedia.org/wiki/Singleton_(mathematics)) character. Single components must conform to the `SingleComponent` protocol and will not be available through regular family iteration.

```swift
final class GameState: SingleComponent {
    var quitGame: Bool = false
}
class GameLogicSystem {
    let gameState: Single<GameState>
    
    init(nexus: Nexus) {
        gameState = nexus.single(GameState.self)
    }
    
    func update() {
        // update your game sate here
        gameState.component.quitGame = true
        
        // entity access is provided as well
        _ = gameState.entity
    }
}

```

### 🔗 Serialization


To serialize/deserialize entities you must conform their assigned components to the `Codable` protocol.  
Conforming components can then be serialized per family like this:

```swift
// MyComponent and YourComponent both conform to Component and Codable protocols.
let nexus = Nexus()
let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)

// JSON encode entities from given family.
var jsonEncoder = JSONEncoder()
let encodedData = try family.encodeMembers(using: &jsonEncoder)

// Decode entities into given family from JSON. 
// The decoded entities will be added to the nexus.
var jsonDecoder = JSONDecoder()
let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)

```

