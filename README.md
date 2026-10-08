# Fireblade ECS (Entity-Component System)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![macOS](https://github.com/fireblade-engine/ecs/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-macos.yml)
[![Linux](https://github.com/fireblade-engine/ecs/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-linux.yml)
[![Windows](https://github.com/fireblade-engine/ecs/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-windows.yml)
[![WASM](https://github.com/fireblade-engine/ecs/actions/workflows/ci-wasm.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-wasm.yml)
[![documentation](https://github.com/fireblade-engine/ecs/workflows/Documentation/badge.svg)](https://fireblade-engine.github.io/ecs)  
[![codecov](https://codecov.io/gh/fireblade-engine/ecs/branch/master/graph/badge.svg)](https://codecov.io/gh/fireblade-engine/ecs)
[![spi-swift-versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffireblade-engine%2Fecs%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/fireblade-engine/ecs)
[![spi-swift-platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffireblade-engine%2Fecs%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/fireblade-engine/ecs)

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) or have a look at [documentation](https://fireblade-engine.github.io/ecs) to get started.

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine and provide a code example.

### 📋 Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [SwiftEnv](https://swiftenv.fuller.li/) for Swift version management - (optional)

### 💻 Installing

Fireblade ECS is available for all platforms that support [Swift 6.1](https://swift.org/) and higher and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager).

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "0.17.7")
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

### 🧩 Component Macro

The `FirebladeECSMacros` product provides the `@Component` macro. It turns a `final class` into a component and implements a set of component protocols from its stored properties, so you don't have to write that code by hand:

| Protocol | Generated | Enables |
| --- | --- | --- |
| `RegistrableComponent` | stable `componentTypeName` (fully qualified type name; declare `static let componentTypeName` to override it) | `nexus.register(_:)`, `nexus.registeredComponentTypes`, `nexus.componentType(named:)` |
| `CloneableComponent` | `init(cloning:context:)`, `clone(context:)` | `entity.clone()`, `nexus.clone(entities:)`, `nexus.clone(into:)` with remapped entity references |
| `SerializableComponent` | `CodingKeys`, `init(from:)`, `encode(to:)` | `nexus.encodeSnapshot(using:handling:)`, `nexus.decodeSnapshot(from:using:)` |
| `InspectableComponent` | `componentProperties` (name, type and key path for each property) | generic inspection, e.g. in editors |
| `DefaultInitializable` | `init()` if every stored property has a default value | `entity[\Position.x] = 1`, state machines |

Add the product to your target:

```swift
.target(
    name: "YourTargetName",
    dependencies: [.product(name: "FirebladeECSMacros", package: "ecs")])
```

```swift
import FirebladeECSMacros

@Component
final class Transform: @unchecked Sendable {
    var position: SIMD3<Float> = .zero
    var parent: Entity?
    @ComponentIgnored var cachedMatrix: [Float] = []  // still cloned, but not serialized or inspected
}

@Component(excluding: .serializable)  // runtime-only component
final class RenderHandle: @unchecked Sendable {
    var handle: Int = 0
}

let nexus = Nexus()
try nexus.register([Transform.self, RenderHandle.self])

// Clone a whole world; entity references (`parent`) are remapped to the clones.
let playMode = Nexus()
try nexus.clone(into: playMode)

// Export and import all serializable components, keyed by their stable type names.
var encoder = JSONEncoder()
let data = try nexus.encodeSnapshot(using: &encoder, handling: .skip)
var decoder = JSONDecoder()
try playMode.decodeSnapshot(from: data, using: &decoder)
```

Component types are registered automatically the first time an instance is assigned. Register them explicitly before decoding snapshots that reference them. All protocols can also be implemented by hand without the macro.

Snapshots start with a `formatVersion` and keep the original entity identifiers. Decoding creates new entities, remaps entity references to them, and rejects snapshots written in a newer format version.

## 🧪 Demo

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## 📖 Documentation

Consult the [online documentation](https://fireblade-engine.github.io/ecs), or preview it locally:

- `make preview-docs`

## 💁 How to contribute

If you want to contribute please see the [CONTRIBUTION GUIDE](CONTRIBUTING.md) first. 

To start your project contribution run these in your command line:

1. `git clone git@github.com:fireblade-engine/ecs.git fireblade-ecs`
2. `cd fireblade-ecs`
3. `make setupEnvironment`

Before commiting code please ensure to run:

- `make precommit`

This project is currently maintained by [Christian Treffs](https://github.com/ctreffs).   
See also the list of [contributors](https://github.com/fireblade-engine/ecs/contributors) who participated in this project.

## 🔏 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Inspired by  

- [Ashley](https://github.com/libgdx/ashley)
- [Entitas](https://github.com/sschmid/Entitas-CSharp)
- [EntitasKit](https://github.com/mzaks/EntitasKit)
