# Fireblade ECS (Entity-Component-System)
[![version 0.3.0](https://img.shields.io/badge/version-0.3.0-brightgreen.svg)](releases/tag/v0.3.0)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![swift version](https://img.shields.io/badge/swift-4-brightgreen.svg)](#)
[![platforms](https://img.shields.io/badge/platform-macOS%20|%20iOS%20|%20linux-brightgreen.svg)](#)

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component-System](https://en.wikipedia.org/wiki/Entity–component–system) implementation in Swift. It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

## Getting Started

These instructions will get you a copy of the project up and running on your local machine and provide a code example.

### Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [Jazzy](https://github.com/realm/jazzy) for documentation - (optional)

### Installing

Fireblade ECS is available for all platforms that support [Swift 4](https://swift.org/) and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: ["FirebladeECS"])
    ]
)

```

## Code Example

<!--Show what the library does as concisely as possible, developers should be able to figure out **how** your project solves their problem by looking at the code example. Make sure the API you are showing off is obvious, and that your code is short and concise.-->

A core element in the Fireblade-ECS is the [Nexus](https://en.wiktionary.org/wiki/nexus#Noun). 
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

This ECS uses a grouping approach for entities with the same component types to optimize and ease up access to these. 
Entities with the same component types may be accessed via a so called family. 
A family has entities as members and component types as family traits.

Create a family by calling `.family` with a set of traits on the nexus.
A family that containts only entities with a `Movement` and `PlayerInput` component, but no `Texture` component is created by

```swift
	let family = nexus.family(requiresAll: [Movement.self, PlayerInput.self], excludesAll: [Texture.self], any: [Name.self])
```

These entities are cached in the nexus for efficient access and iteration.
Iterate family members by calling `.iterate` on the family you want to iterate over.
`iterate` provides a closure whose parameters start with the entity identifier (entityId) of the current entity, 
followed by the typesafe component instances of the current entity that you may provide in your desired order. 

```swift
class PlayerMovementSystem {
	let family = nexus.family(requiresAll: [Movement.self, PlayerInput.self], excludesAll: [Texture.self], any: [Name.self])

	func update() {
		family.iterate { (_, mov: Movement!, input: PlayerInput!, name: Name?) in
			
			// position & velocity for the current entity
			// we know that we will have this component so we force unwrap the component instance parameter already for easy handling inside the closure
			
			// get properties
			_ = mov.position
			_ = mov.velocity
			
			// set properties
			mov.position.x = mov.position.x + 3.0
			...
			
			// current input command for the given entity
			_ = input.command
			...
			
			// optional name component that may or may not be part of the current entity
			_ = name?.name
			...
			
		}
	}
}
```

<!--## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.-->

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
