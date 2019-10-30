# Fireblade ECS (Entity-Component System)
[![Build Status](https://travis-ci.com/fireblade-engine/ecs.svg?branch=master)](https://travis-ci.com/fireblade-engine/ecs)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![swift version](https://img.shields.io/badge/swift-5.0+-brightgreen.svg)](https://swift.org/download)
[![platforms](https://img.shields.io/badge/platforms-%20macOS%20|%20iOS%20|%20tvOS%20|%20watchOS-brightgreen.svg)](#)
[![platforms](https://img.shields.io/badge/platforms-linux-brightgreen.svg)](#)

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine and provide a code example.

### 📋 Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [SwiftEnv](https://swiftenv.fuller.li/) for Swift version management - (optional)

### 💻 Installing

Fireblade ECS is available for all platforms that support [Swift 5.0](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: ["FirebladeECS"])
    ]
)

```

## 📝 Code Example

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
let myEntity = nexus.createEntity()
```

You can define `Components` like this

```swift
class Movement: Component {
	var position: (x: Double, y: Double) = (0.0, 1.0)
	var velocity: Double = 0.1
}
```
and assign instances of them to an `Entity` with

```swift
let movement = Movement()
myEntity.assign(movement)
```

### 👪 Families

This ECS uses a grouping approach for entities with the same component types to optimize cache locality and ease up access to them.   
Entities with the __same component types__ may belong to one `Family`. 
A `Family` has entities as members and component types as family traits.

Create a family by calling `.family` with a set of traits on the nexus.
A family that containts only entities with a `Movement` and `PlayerInput` component, but no `Texture` component is created by

```swift
let family = nexus.family(requiresAll: Movement.self, PlayerInput.self,
                          excludesAll: Texture.self)
```

These entities are cached in the nexus for efficient access and iteration.
Families conform to the [Sequence](https://developer.apple.com/documentation/swift/sequence) protocol so that members (components) 
may be iterated and accessed like any other sequence in Swift.   
Access a familiy's components directly on the family instance. To get family entities and access components at the same time call `family.entityAndComponents`.
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
			
			// the currenty entity instance
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
			
			// the currenty entity instance
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

### 👫 Relatives

This ECS implementation provides an integrated way of creating a [directed acyclic graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph) hierarchy of entities by forming parent-child relationships. Entities can become children of a parent entity. In family terms they become **relatives**. Families provide iteration over these relationships.   
The entity hierachy implementation does not use an additional component therefore keeping the hierarchy intact over different component-families.
This feature is especially useful for implenting a [scene graph](https://en.wikipedia.org/wiki/Scene_graph). 

```swift
// create entities with 0 to n components
let parent: Entity = nexus.createEntity(with: Position(x: 1, y: 1), SomeOtherComponent(...))
let child: Entity  = nexus.createEntity(with: Position(x: 2, y: 2))
let child2: Entity = nexus.createEntity(with: Position(x: 3, y: 3), MySpecialComponent(...))

// create relationships between entities
parent.addChild(child)
child.addChild(child2)
// or remove them
// parent.removeChild(child)

// iterate over component families descending the graph
nexus.family(requires: Position.self)
     .descendRelatives(from: parent) // provide the start entity (aka root "node")
     .forEach { (parent: Position, child: Position) in
        // parent: the current parent component
        // child: the current child component
        
        // update your components hierarchically
        child.x += parent.x
        child.y += parent.y
     }
```

## 🧪 Demo

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## 🏷️ Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/fireblade-engine/ecs/tags). 

## ✍️ Authors

* [Christian Treffs](https://github.com/ctreffs) - *Initial work*
* [Manuel Weidmann](https://github.com/vyo)

See also the list of [contributors](https://github.com/fireblade-engine/ecs/contributors) who participated in this project.

## 🔏 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Inspired by  

- [Ashley](https://github.com/libgdx/ashley)
- [Entitas](https://github.com/sschmid/Entitas-CSharp)
- [EntitasKit](https://github.com/mzaks/EntitasKit)
