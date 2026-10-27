# Fireblade ECS (Entity-Component System)
[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![macOS](https://github.com/fireblade-engine/ecs/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-macos.yml)
[![iOS](https://github.com/fireblade-engine/ecs/actions/workflows/ci-ios.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-ios.yml)
[![Linux](https://github.com/fireblade-engine/ecs/actions/workflows/ci-linux.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-linux.yml)
[![Windows](https://github.com/fireblade-engine/ecs/actions/workflows/ci-windows.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-windows.yml)
[![WASM](https://github.com/fireblade-engine/ecs/actions/workflows/ci-wasm.yml/badge.svg)](https://github.com/fireblade-engine/ecs/actions/workflows/ci-wasm.yml)
[![documentation](https://github.com/fireblade-engine/ecs/actions/workflows/docs.yml/badge.svg)](https://fireblade-engine.github.io/ecs)  
[![codecov](https://codecov.io/gh/fireblade-engine/ecs/branch/main/graph/badge.svg)](https://codecov.io/gh/fireblade-engine/ecs)
[![spi-swift-versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffireblade-engine%2Fecs%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/fireblade-engine/ecs)
[![spi-swift-platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffireblade-engine%2Fecs%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/fireblade-engine/ecs)

This is a **dependency free**, **lightweight**, **fast** and **easy to use** [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) implementation in Swift. Components are value types, identifiers are generational, and the default archetype storage iterates families linearly (see the [benchmarks](Benchmarks/README.md)). With 10 000 entities, `forEach(reading:writing:)` over two components takes about 4 μs on the archetype storage; 1.x needed about 1 220 μs for a plain iteration of two components (release build, Apple silicon, `make benchmark`). It is developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

Coming from 1.x? Read the [migration guide](https://fireblade-engine.github.io/ecs/documentation/firebladeecs/migratingtofirebladeecs2) first, and see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) or the [documentation](https://fireblade-engine.github.io/ecs) to get started.

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine and provide a code example.

### 📋 Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Homebrew](https://brew.sh/) - (optional)
* [Mint](https://github.com/mintable/mint) for tool management - (optional)
* [Swiftlint](https://github.com/realm/SwiftLint) for linting - (optional)
* [SwiftEnv](https://swiftenv.fuller.li/) for Swift version management - (optional)

### 💻 Installing

Fireblade ECS 2 needs [Swift 6.2](https://swift.org/) or later and the [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager). It runs on macOS, iOS, tvOS, watchOS, visionOS, Linux, Windows and WebAssembly.

Extend the following lines in your `Package.swift` file or use it to create a new project.

```swift
// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "YourTargetName",
            dependencies: [
                .product(name: "FirebladeECS", package: "ecs")
            ])
    ]
)

```

The package provides three products:

| Product | Provides | Dependencies |
| --- | --- | --- |
| `FirebladeECS` | `Nexus`, `Entity`, `Family`, `Single`, events, snapshots | none |
| `FirebladeECSMacros` | the `@Component` and `@FamilyTraits` macros | [swift-syntax](https://github.com/swiftlang/swift-syntax) |
| `FirebladeFSM` | `EntityStateMachine`, `EntityState`, component providers | `FirebladeECS` |

**Import rule:** `FirebladeECSMacros` and `FirebladeFSM` do not re-export `FirebladeECS`. Add each product you use to the target and import `FirebladeECS` in every file next to the module you need:

```swift
import FirebladeECS
import FirebladeECSMacros   // only where @Component or @FamilyTraits is used
import FirebladeFSM         // only where the state machine is used
```

## 📝 Code Example

### 🏛️ Nexus

The core element in the Fireblade-ECS is the [Nexus](https://en.wiktionary.org/wiki/nexus#Noun). 
It acts as a centralized way to store, access and manage entities and their components. 
You may use more than one `Nexus` at a time.

Initialize a `Nexus` with

```swift
let nexus = Nexus()                        // archetype storage (default)
let churning = Nexus(storage: .sparseSet)  // for worlds that add and remove components constantly
```

### 👤 Entities

then create entities by letting the `Nexus` generate them.

```swift
// an entity without components
let newEntity = nexus.createEntity()
```

Components are value types. Conform a struct or enum to the `Component` protocol

```swift
struct Position: Component {
    var x: Int = 0
    var y: Int = 0
}
```
and `set` values of it on an `Entity`. Setting adds the component, or replaces the one the entity already has.

```swift
newEntity.set(Position(x: 1, y: 2))
```

Reading a component returns a **copy**. Change the stored component with `modify`, a subscript or `set`:

```swift
let copy = newEntity.get(Position.self)                      // Position?, a copy
newEntity.modify(Position.self) { $0.x += 1 }                // in place, false if missing
newEntity[Position.self]?.y += 1                             // in place through the subscript
newEntity.modify(Position.self, default: Position()) { $0.x += 1 }  // adds the default if missing
```

You can be more efficient by assigning components while creating an entity.

```swift
// an entity with two components assigned.
nexus.createEntity {
    Position(x: 1, y: 2)
    Velocity(dx: 1, dy: 0)
}

// bulk create entities with multiple components assigned.
nexus.createEntities(count: 100) { _ in
    Position()
    Velocity()
}

```
### 👪 Families

This ECS uses a grouping approach for entities with the same component types to optimize cache locality and ease up access to them.   
Entities with the __same component types__ may belong to one `Family`. 
A `Family` has entities as members and component types as family traits.

Create a family by calling `.family` with a set of traits on the nexus.
A family that contains only entities with a `Position` and `Velocity` component, but no `Frozen` component is created by

```swift
let family = nexus.family(requiresAll: Position.self, Velocity.self,
                          excludesAll: Frozen.self)
```

Update the members with `forEach(reading:writing:)`. The read components arrive as copies, the written ones as `inout`, and the changes land in the storage. This is the fast path: no allocation and no lookup per member.

```swift
struct Frozen: Component {}
struct Velocity: Component { var dx = 0, dy = 0 }

final class MovementSystem {
    let family: Family<Position, Velocity>

    init(nexus: Nexus) {
        family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Frozen.self)
    }

    func update() {
        family.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
            position.x += velocity.dx
            position.y += velocity.dy
        }
    }
}
```

> [!WARNING]
> **The `for var` hazard.** Plain iteration, `get` and the entity API hand out *copies*. This compiles, runs, and changes nothing:
>
> ```swift
> for (var position, velocity) in family {   // `position` is a copy
>     position.x += velocity.dx              // lost
> }
> ```
>
> The compiler cannot catch it. Write with `forEach(reading:writing:)`, `entity.modify` or `entity.set`. Plain `for` loops are fine for read-only systems.

Families conform to the [Sequence](https://developer.apple.com/documentation/swift/sequence) protocol for read-only access.
To get family entities and components at the same time call `family.entityAndComponents`.
If you are only interested in a family's entities call `family.entities`.

```swift
func inspect(_ family: Family<Position, Velocity>) {
    for (position, velocity) in family {
        _ = (position.x, velocity.dx)   // read-only copies
    }
    for (entity, position, _) in family.entityAndComponents {
        _ = (entity.identifier, position)
    }
    for entity in family.entities {
        entity.modify(Position.self) { $0.x = 0 }   // write through the entity
    }
}
```

With the `FirebladeECSMacros` product a family can be declared once as a type, see the [documentation](https://fireblade-engine.github.io/ecs):

```swift
@FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
struct Movers {}

Movers(in: nexus).forEach { velocity, position in position.x += velocity.dx }
```

### 🧑 Singles

A `Single` on the other hand is a special kind of family that holds exactly **one** entity with exactly **one** component for the entire lifetime of the Nexus. This may come in handy if you have components that have a [Singleton](https://en.wikipedia.org/wiki/Singleton_(mathematics)) character. Single components must conform to the `SingleComponent` protocol and will not be available through regular family iteration.

```swift
struct GameState: SingleComponent {
    var quitGame: Bool = false
}
class GameLogicSystem {
    let gameState: Single<GameState>
    
    init(nexus: Nexus) {
        gameState = nexus.single(GameState.self)
    }
    
    func update() {
        // `component` is a read-only copy: write with `modify` or `set`
        gameState.modify { $0.quitGame = true }
        
        // entity access is provided as well
        _ = gameState.entity
    }
}

```

### 🆔 Entity identifiers

An `EntityIdentifier` is a 64 bit value of slot index and generation. When an entity is destroyed, its identifier goes stale and never matches a later entity in the same slot:

```swift
let id = newEntity.identifier
nexus.destroy(entity: newEntity)
nexus.isAlive(id)    // false
nexus.entity(id)     // nil
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

The `FirebladeECSMacros` product provides the `@Component` macro. It turns a `struct` or `enum` into a component and implements a set of component protocols from its stored properties, so you don't have to write that code by hand:

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
import FirebladeECS
import FirebladeECSMacros

@Component
struct Transform {
    var position: SIMD3<Float> = .zero
    var parent: EntityIdentifier?
    @ComponentIgnored var cachedMatrix: [Float] = []  // still cloned, but not serialized or inspected
}

@Component(excluding: .serializable)  // runtime-only component
struct RenderHandle: @unchecked Sendable {
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

Component types are registered automatically the first time a value is set. Register them explicitly before decoding snapshots that reference them. All protocols can also be implemented by hand without the macro.

Snapshots start with a `formatVersion` and keep the original entity identifiers, including their generations (older versions still load). Decoding creates new entities, remaps entity references to them, and rejects snapshots written in a newer format version.

## 🔀 Entity State Machines

The optional `FirebladeFSM` product provides `EntityStateMachine`, `EntityState` and the component providers. A state machine swaps the components of an entity when it changes state. Add the product next to `FirebladeECS` and import both modules:

```swift
.target(
    name: "YourTargetName",
    dependencies: [
        .product(name: "FirebladeECS", package: "ecs"),
        .product(name: "FirebladeFSM", package: "ecs")
    ])
```

```swift
import FirebladeECS
import FirebladeFSM
```

## 🧪 Demo

See the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) to get started.

## 📖 Documentation

Consult the [online documentation](https://fireblade-engine.github.io/ecs), or preview it locally:

- `make docs-preview`

## 💁 How to contribute

If you want to contribute please see the [CONTRIBUTION GUIDE](CONTRIBUTING.md) first. 

To start your project contribution run these in your command line:

1. `git clone git@github.com:fireblade-engine/ecs.git fireblade-ecs`
2. `cd fireblade-ecs`
3. `make setup`

Before commiting code please ensure to run:

- `make pre-commit`

To measure runtime performance run `make benchmark` (see [Benchmarks/README.md](Benchmarks/README.md)).

This project is currently maintained by [Christian Treffs](https://github.com/ctreffs).   
See also the list of [contributors](https://github.com/fireblade-engine/ecs/contributors) who participated in this project.

## 🔏 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

Inspired by  

- [Ashley](https://github.com/libgdx/ashley)
- [Entitas](https://github.com/sschmid/Entitas-CSharp)
- [EntitasKit](https://github.com/mzaks/EntitasKit)
