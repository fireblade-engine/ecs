# Fireblade ECS (Entity-Component-System)
[![Build Status](https://travis-ci.com/fireblade-engine/ecs.svg?branch=master)](https://travis-ci.com/fireblade-engine/ecs)
[![version 0.5.1](https://img.shields.io/badge/version-0.5.1-brightgreen.svg)](releases/tag/v0.5.1)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![swift version](https://img.shields.io/badge/swift-4.2-brightgreen.svg)](#)
[![platforms](https://img.shields.io/badge/platforms-%20macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20linux%20-brightgreen.svg)](#)

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component-System](https://en.wikipedia.org/wiki/Entity–component–system) implementation in Swift. It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine and provide a code example.

### Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [Jazzy](https://github.com/realm/jazzy) for documentation - (optional)

### Installing

Fireblade ECS is available for all platforms that support [Swift 4.2](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "0.5.1")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: ["FirebladeECS"])
    ]
)

```

## Code Example

The core element in the Fireblade-ECS is the [Nexus](https://en.wiktionary.org/wiki/nexus#Noun). 
It acts as a centralized way to store, access and manage entities and their components. 
A single `Nexus` may hold up to 4294967295 `Entities` at a time.
You may use more than one `Nexus`.

Initialize a nexus with

```swift
let nexus = Nexus()
```

then create entities by letting the `Nexus` generate them.

```swift
let myEntity = nexus.create(entity: "myEntity")
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
myEntity.assign(Movement())
```

This ECS uses a grouping approach for entities with the same component types to optimize and ease up access to them.   
Entities with the same component types may be accessed via a so called `family`. 
A `family` has entities as members and component types as family traits.

Create a family by calling `.family` with a set of traits on the nexus.
A family that containts only entities with a `Movement` and `PlayerInput` component, but no `Texture` component is created by

```swift
let family = nexus.family(requiresAll: Movement.self, PlayerInput.self,
                          excludesAll: Texture.self)
```

These entities are cached in the nexus for efficient access and iteration.
Families conform to the [Sequence](https://developer.apple.com/documentation/swift/sequence) so that members (components) 
may be iterated and accessed like any other sequence in Swift.   
Access a familiy's components directly on the family instance. To get each entity to the accessed components call `family.entityAndComponents`.
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

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](tags). 

## Authors

* [Christian Treffs](https://github.com/ctreffs) - *Initial work*
* [Manuel Weidmann](https://github.com/vyo)

See also the list of [contributors](project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments

Inspired by  

- [Ashley](https://github.com/libgdx/ashley)
- [Entitas](https://github.com/sschmid/Entitas-CSharp)
- [EntitasKit](https://github.com/mzaks/EntitasKit)
