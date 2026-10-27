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

---

## ⚡ 1-Minute Quickstart

```swift
import FirebladeECS

struct Position: Component { var x = 0, y = 0 }
struct Velocity: Component { var dx = 0, dy = 0 }

let nexus = Nexus()
let entity = nexus.createEntity {
    Position(x: 0, y: 0)
    Velocity(dx: 1, dy: 2)
}

let family = nexus.family(requiresAll: Position.self, Velocity.self)
family.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    position.x += velocity.dx
    position.y += velocity.dy
}
print(entity.get(Position.self)!) // Position(x: 1, y: 2)
```

---

## 🚀 Tier 1: Core ECS Essentials

### The Nexus
The core element in Fireblade-ECS is the [Nexus](https://en.wiktionary.org/wiki/nexus#Noun). It acts as a centralized manager to store, access, and manage entities and their components. You may use more than one `Nexus` at a time.

```swift
let nexus = Nexus() // archetype storage (default)
```

### Defining & Managing Components & Entities
Components are value types conforming to the `Component` protocol:

```swift
struct Position: Component {
    var x: Int = 0
    var y: Int = 0
}
```

Create entities and assign or modify components:

```swift
let newEntity = nexus.createEntity()
newEntity.set(Position(x: 1, y: 2))

// Reading returns a copy
let copy = newEntity.get(Position.self)

// Modifying in place
newEntity.modify(Position.self) { $0.x += 1 }
newEntity[Position.self]?.y += 1
newEntity.modify(Position.self, default: Position()) { $0.x += 1 }

// Creating entities with components inline or in bulk
nexus.createEntity {
    Position(x: 1, y: 2)
    Velocity(dx: 1, dy: 0)
}

nexus.createEntities(count: 100) { _ in
    Position()
    Velocity()
}
```

### Families & Fast-Path Systems
Entities with the same component types belong to a `Family`. Create families by calling `.family` with component traits:

```swift
let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Frozen.self)
```

Update members with `forEach(reading:writing:)` for the archetype-optimized fast path (no allocation or per-member lookup):

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
> The compiler cannot catch it. Always use `forEach(reading:writing:)`, `entity.modify`, or `entity.set` for mutations. Plain `for` loops are fine for read-only iteration or accessing `.entityAndComponents` / `.entities`.

Families conform to `Sequence` for read-only iteration:

```swift
for (position, velocity) in family {
    _ = (position.x, velocity.dx) // read-only copies
}
for (entity, position, _) in family.entityAndComponents {
    _ = (entity.identifier, position)
}
for entity in family.entities {
    entity.modify(Position.self) { $0.x = 0 }
}
```

---

## 🧩 Tier 2: Ergonomics with Macros (`FirebladeECSMacros`)

### `@Component` Macro
The `FirebladeECSMacros` product provides the `@Component` macro, which automatically implements component protocols based on stored properties:

| Protocol | Generated | Enables |
| --- | --- | --- |
| `RegistrableComponent` | stable `componentTypeName` | `nexus.register(_:)`, `nexus.registeredComponentTypes`, `nexus.componentType(named:)` |
| `CloneableComponent` | `init(cloning:context:)`, `clone(context:)` | `entity.clone()`, `nexus.clone(entities:)`, `nexus.clone(into:)` with remapped references |
| `SerializableComponent` | `CodingKeys`, `init(from:)`, `encode(to:)` | `nexus.encodeSnapshot(...)`, `nexus.decodeSnapshot(...)` |
| `InspectableComponent` | `componentProperties` (name, type, key path) | Generic runtime inspection (e.g. editors) |
| `DefaultInitializable` | `init()` if all properties have defaults | `entity[\Position.x] = 1`, state machines |

Use `@ComponentIgnored` to skip specific properties from serialization or inspection, or configure exclusion flags:

```swift
@Component
struct Transform {
    var position: SIMD3<Float> = .zero
    var parent: EntityIdentifier?
    @ComponentIgnored var cachedMatrix: [Float] = []
}

@Component(excluding: .serializable)
struct RenderHandle: @unchecked Sendable {
    var handle: Int = 0
}
```

### `@FamilyTraits` Macro
Declare families cleanly as types using `@FamilyTraits`:

```swift
@FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
struct Movers {}

Movers(in: nexus).forEach { velocity, position in
    position.x += velocity.dx
}
```

---

## 🔄 Tier 3: Lifecycle, State & Persistence

### Generational Entity Identifiers
An `EntityIdentifier` consists of a slot index and generation. When an entity is destroyed, its identifier becomes stale and safely rejects subsequent operations:

```swift
let id = newEntity.identifier
nexus.destroy(entity: newEntity)
nexus.isAlive(id) // false
nexus.entity(id)  // nil
```

### Singles
A `Single` holds exactly one entity with exactly one component for the lifetime of the `Nexus`, representing singleton-like state.

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

### World Snapshots & Cloning
Clone worlds or encode/decode snapshots of families or entire nexuses:

```swift
let playMode = Nexus()
try nexus.clone(into: playMode)

// Snapshots
var encoder = JSONEncoder()
let data = try nexus.encodeSnapshot(using: &encoder, handling: .skip)
var decoder = JSONDecoder()
try playMode.decodeSnapshot(from: data, using: &decoder)

// Family serialization
let family = nexus.family(requiresAll: MyComponent.self)
let encodedData = try family.encodeMembers(using: &jsonEncoder)
let decodedEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
```

---

## ⚙️ Tier 4: Advanced Architecture & Extensions

### Storage Trade-offs
- **Archetype Storage (Default):** Entities with identical component combinations are stored in dense, cache-local memory arrays. Optimized for fast, linear iteration across families.
- **Sparse Set Storage (`Nexus(storage: .sparseSet)`):** Ideal for worlds with extremely high structural churn (frequent component additions and removals).

### Entity State Machines
The optional `FirebladeFSM` product provides `EntityStateMachine`, `EntityState`, and component providers to swap components dynamically when an entity changes states.

```swift
import FirebladeECS
import FirebladeFSM
```

---

## 📦 Installation & Setup

### Prerequisites
* [Swift Package Manager (SPM)](https://github.com/apple/swift-package-manager)
* [Homebrew](https://brew.sh/) - (optional)
* [Mint](https://github.com/mintable/mint) for tool management - (optional)
* [SwiftLint](https://github.com/realm/SwiftLint) for linting - (optional)
* [SwiftEnv](https://swiftenv.fuller.li/) for Swift version management - (optional)

### `Package.swift` Integration
Fireblade ECS requires Swift 6.2 or later.

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
                .product(name: "FirebladeECS", package: "ecs"),
                .product(name: "FirebladeECSMacros", package: "ecs"), // optional
                .product(name: "FirebladeFSM", package: "ecs")       // optional
            ])
    ]
)
```

### Products & Import Guidelines
| Product | Provides | Dependencies |
| --- | --- | --- |
| `FirebladeECS` | `Nexus`, `Entity`, `Family`, `Single`, events, snapshots | none |
| `FirebladeECSMacros` | `@Component` and `@FamilyTraits` macros | [swift-syntax](https://github.com/swiftlang/swift-syntax) |
| `FirebladeFSM` | `EntityStateMachine`, `EntityState`, component providers | `FirebladeECS` |

**Import Rule:** `FirebladeECSMacros` and `FirebladeFSM` do not re-export `FirebladeECS`. Import `FirebladeECS` alongside any auxiliary module:

```swift
import FirebladeECS
import FirebladeECSMacros   // only where macros are used
import FirebladeFSM         // only where state machines are used
```

---

## 🧪 Demo & Documentation

- **Demo App:** Explore the [Fireblade ECS Demo App](https://github.com/fireblade-engine/ecs-demo).
- **Documentation:** Read the [online documentation](https://fireblade-engine.github.io/ecs) or preview it locally:
  - `make docs-preview`

---

## 💁 Contributing & Development

If you want to contribute, please review the [CONTRIBUTION GUIDE](CONTRIBUTING.md) first.

To set up your development environment:
1. `git clone git@github.com:fireblade-engine/ecs.git fireblade-ecs`
2. `cd fireblade-ecs`
3. `make setup`

Before committing code, ensure checks pass:
- `make pre-commit`

To measure performance:
- `make benchmark` (see [Benchmarks/README.md](Benchmarks/README.md))

Maintained by [Christian Treffs](https://github.com/ctreffs) and [contributors](https://github.com/fireblade-engine/ecs/contributors).

---

## 🔏 License & Acknowledgments

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Inspired by:
- [Ashley](https://github.com/libgdx/ashley)
- [Entitas](https://github.com/sschmid/Entitas-CSharp)
- [EntitasKit](https://github.com/mzaks/EntitasKit)
