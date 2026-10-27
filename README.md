# Fireblade ECS

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

A dependency-free, lightweight, fast, and easy-to-use [Entity-Component System](https://en.wikipedia.org/wiki/Entity_component_system) for Swift. Components are value types, identifiers are generational, and the default archetype storage iterates families linearly. Developed and maintained as part of the [Fireblade Game Engine project](https://github.com/fireblade-engine).

Coming from 1.x? Read the [migration guide](https://fireblade-engine.github.io/ecs/documentation/firebladeecs/migratingtofirebladeecs2), and see the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) or the [online documentation](https://fireblade-engine.github.io/ecs).

---

## Installation

Fireblade ECS requires Swift 6.2 or later and Swift Package Manager (SPM). It supports macOS, iOS, tvOS, watchOS, visionOS, Linux, Windows, and WebAssembly.

Add Fireblade ECS to your `Package.swift`:

```swift
// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "MyGame",
    dependencies: [
        .package(url: "https://github.com/fireblade-engine/ecs.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "MyGame",
            dependencies: [
                .product(name: "FirebladeECS", package: "ecs"),
                .product(name: "FirebladeECSMacros", package: "ecs"), // Optional: @Component and @FamilyTraits
                .product(name: "FirebladeFSM", package: "ecs")        // Optional: Entity state machines
            ])
    ]
)
```

Import `FirebladeECS` in your source files:

```swift
import FirebladeECS
import FirebladeECSMacros // Only where @Component or @FamilyTraits is used
import FirebladeFSM       // Only where entity state machines are used
```

---

## Quickstart

```swift
import FirebladeECS

// 1. Define value-type components
struct Position: Component { var x = 0, y = 0 }
struct Velocity: Component { var dx = 0, dy = 0 }

// 2. Initialize a Nexus and create an entity
let nexus = Nexus()
let entity = nexus.createEntity {
    Position(x: 0, y: 0)
    Velocity(dx: 1, dy: 2)
}

// 3. Query matching entities and update in place
let family = nexus.family(requiresAll: Position.self, Velocity.self)
family.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
    position.y += velocity.dy
}
```

---

## Usage

### The Nexus

The `Nexus` is the central manager that stores, organizes, and indexes entities and their components.

```swift
let nexus = Nexus()                            // Archetype storage (default)
let churningNexus = Nexus(storage: .sparseSet) // Sparse set storage
```

Fireblade ECS supports two storage models:
- **Archetype Storage (Default):** Entities with identical component combinations are packed contiguously in cache-local memory arrays. Highly optimized for linear, fast system iteration.
- **Sparse Set Storage (`storage: .sparseSet`):** Stores components in separate sparse sets. Ideal for worlds with high structural churn (frequent component addition and removal).

### Components & Entities

Components are value types conforming to `Component`:

```swift
struct Position: Component {
    var x: Int = 0
    var y: Int = 0
}
```

Create entities and manage their components:

```swift
let entity = nexus.createEntity()

// Assign or replace a component instance
entity.set(Position(x: 1, y: 2))

// Read a component (returns a copy)
let copy = entity.get(Position.self) // Position?, a copy

// Mutate a component in place (avoids copying and replacing the entire struct)
entity.modify(Position.self) { $0.x += 1 }
entity[Position.self]?.y += 1
entity.modify(Position.self, default: Position()) { $0.x += 1 }

// Create an entity with components inline:
nexus.createEntity {
    Position(x: 1, y: 2)
    Velocity(dx: 1, dy: 0)
}

// Bulk create entities:
nexus.createEntities(count: 100) { _ in
    Position()
    Velocity()
}
```

### Families & Systems

A `Family` groups entities that share specific component traits for fast, cache-local iteration:

```swift
let family = nexus.family(requiresAll: Position.self, Velocity.self,
                          excludesAll: Frozen.self)
```

Use `forEach(reading:writing:)` to update entities. `reading:` passes immutable copies, while `writing:` passes mutable `inout` references that write directly back to storage without heap allocations:

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
> **The `for var` hazard:** Value types returned by `get` or sequence iteration are *copies*. Mutating a local `var` in a loop does not change stored data:
>
> ```swift
> for (var position, velocity) in family { // `position` is a copy
>     position.x += velocity.dx            // lost!
> }
> ```
> Always mutate components through `forEach(reading:writing:)`, `entity.modify`, or `entity.set`.

For read-only operations, families conform to standard `Sequence`:

```swift
func inspect(_ family: Family<Position, Velocity>) {
    for (position, velocity) in family {
        _ = (position.x, velocity.dx) // Read-only copies
    }
    for (entity, position, _) in family.entityAndComponents {
        _ = (entity.identifier, position)
    }
    for entity in family.entities {
        entity.modify(Position.self) { $0.x = 0 }
    }
}
```

---

## Macros

The optional `FirebladeECSMacros` product provides Swift macros to synthesize boilerplate code automatically.

### `@Component`

`@Component` synthesizes protocol conformances based on stored properties:

| Generated Protocol | Enables |
| --- | --- |
| `RegistrableComponent` | Stable `componentTypeName` for type registry lookup |
| `CloneableComponent` | `entity.clone()` and world cloning with remapped entity references |
| `SerializableComponent` | `nexus.encodeSnapshot(...)` and `nexus.decodeSnapshot(...)` |
| `InspectableComponent` | Runtime property reflection (name, type, key paths) for editors |
| `DefaultInitializable` | `init()` if all stored properties have default values |

```swift
@Component
struct Transform {
    var position: SIMD3<Float> = .zero
    var parent: EntityIdentifier?
    @ComponentIgnored var cachedMatrix: [Float] = [] // Cloned, but not serialized or inspected
}

@Component(excluding: .serializable) // Runtime-only component
struct RenderHandle: @unchecked Sendable {
    var handle: Int = 0
}
```

### `@FamilyTraits`

Declare family requirements as distinct types:

```swift
@FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
struct Movers {}

Movers(in: nexus).forEach { velocity, position in
    position.x += velocity.dx
}
```

---

## Persistence & Lifecycle

### Generational Entity Identifiers

An `EntityIdentifier` combines a slot index with a generation counter. When an entity is destroyed, its identifier goes stale and safely rejects subsequent lookups:

```swift
let id = entity.identifier
nexus.destroy(entity: entity)
nexus.isAlive(id) // false
nexus.entity(id)  // nil
```

### Singletons (`Single`)

A `Single` represents an entity with exactly one component that persists throughout the lifetime of the `Nexus`:

```swift
struct GameState: SingleComponent {
    var quitGame: Bool = false
}

final class GameLogicSystem {
    let gameState: Single<GameState>
    
    init(nexus: Nexus) {
        gameState = nexus.single(GameState.self)
    }
    
    func update() {
        gameState.modify { $0.quitGame = true }
        _ = gameState.entity
    }
}
```

### Snapshots & World Cloning

Clone entire worlds or encode and decode snapshots:

```swift
// Clone an entire world (entity references like parent/child are automatically remapped)
let playMode = Nexus()
try nexus.clone(into: playMode)

// Export and import full-world snapshots
var encoder = JSONEncoder()
let data = try nexus.encodeSnapshot(using: &encoder, handling: .skip)
var decoder = JSONDecoder()
try playMode.decodeSnapshot(from: data, using: &decoder)

// Family-level serialization
let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
var jsonEncoder = JSONEncoder()
let encodedData = try family.encodeMembers(using: &jsonEncoder)
var jsonDecoder = JSONDecoder()
let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
```

---

## Entity State Machines

The optional `FirebladeFSM` product provides `EntityStateMachine` to dynamically swap components on an entity when it transitions between states:

```swift
import FirebladeECS
import FirebladeFSM

enum EnemyBehavior {
    case patrol
    case attack
}

struct Patrol: Component, DefaultInitializable {}
struct Attack: Component, DefaultInitializable {}

let entity = nexus.createEntity()
let fsm = EntityStateMachine<EnemyBehavior>(entity: entity)

// Define states and assign component types
fsm.createState(name: .patrol)
    .addType(Patrol.self)

fsm.createState(name: .attack)
    .addType(Attack.self)

// Transition state: removes previous state components and adds new state components
fsm.changeState(name: .attack)
```

---

## Documentation

- **Online Documentation:** Read the [API Documentation](https://fireblade-engine.github.io/ecs).
- **Local Preview:** Preview documentation locally with:
  ```sh
  make docs-preview
  ```

---

## Demo

Explore the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo) for practical examples, particle simulations, and asteroid games.

---

## Contributing

This project is maintained by [Christian Treffs](https://github.com/ctreffs) and [contributors](https://github.com/fireblade-engine/ecs/contributors). Please review the [Contribution Guide](CONTRIBUTING.md) before submitting changes.

### Prerequisites

* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Homebrew](https://brew.sh/) (optional)
* [Mint](https://github.com/yonaskolb/Mint) (optional)
* [SwiftLint](https://github.com/realm/SwiftLint) (optional)
* [SwiftEnv](https://swiftenv.fuller.li/) (optional)

### Development Workflow

1. Clone and set up:
   ```sh
   git clone git@github.com:fireblade-engine/ecs.git fireblade-ecs
   cd fireblade-ecs
   make setup
   ```
2. Verify changes before committing:
   ```sh
   make pre-commit
   ```
3. Run benchmarks:
   ```sh
   make benchmark
   ```

---

## License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

Inspired by [Ashley](https://github.com/libgdx/ashley), [Entitas](https://github.com/sschmid/Entitas-CSharp), and [EntitasKit](https://github.com/mzaks/EntitasKit).
