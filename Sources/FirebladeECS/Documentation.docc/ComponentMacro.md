# Generating components with the component macro

Implement registration, cloning, snapshots and inspection for a component from its stored properties.

## Overview

The optional `FirebladeECSMacros` product provides the `@Component` macro.
It turns a `struct` or `enum` into a component and implements a set of component protocols from its stored properties, so you don't have to write that code by hand:

| Protocol | Generated | Enables |
| --- | --- | --- |
| ``RegistrableComponent`` | stable `componentTypeName` | `nexus.register(_:)`, `nexus.registeredComponentTypes`, `nexus.componentType(named:)` |
| ``CloneableComponent`` | `init(cloning:context:)`, `clone(context:)` | `entity.clone()`, `nexus.clone(entities:)`, `nexus.clone(into:)` |
| ``SerializableComponent`` | `CodingKeys`, `init(from:)`, `encode(to:)` | `nexus.encodeSnapshot(using:handling:)`, `nexus.restoreSnapshot(from:using:)`, `nexus.decodeSnapshot(from:using:)`, `Nexus: Codable` |
| ``InspectableComponent`` | `componentProperties` | generic inspection, e.g. in editors |
| ``DefaultInitializable`` | `init()` if every stored property has a default value (structs) | key path assignment, state machines |
| ``Component`` | `static let componentIndex` | typed lookups read a plain static instead of taking the registry lock |

The core `FirebladeECS` library stays dependency free. Only `FirebladeECSMacros` depends on [swift-syntax](https://github.com/swiftlang/swift-syntax).
All protocols can also be implemented by hand without the macro.

### Adding the product

Add the product to your target. It re-exports `FirebladeECS`.

```swift
.target(
    name: "YourTargetName",
    dependencies: [.product(name: "FirebladeECSMacros", package: "ecs")])
```

### Declaring components

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
```

- The stable type name defaults to the fully qualified type name. Declare `static let componentTypeName` to override it.
- After renaming a persisted type, list its former names in `static let componentTypeNameAliases` so existing snapshots keep loading. See <doc:SavingAndLoadingScenes>.
- `@Component(excluding:)` takes a `ComponentMacroFeatures` set: `.cloneable`, `.serializable`, `.inspectable` and `.defaultInit`. Registration is always implemented.
- `@ComponentIgnored` keeps a stored property out of serialization and inspection. Ignored properties are still cloned and need a default value.
- Serialized properties need an explicit type annotation. `let` constants with an initial value are not serialized.
- Members you declare yourself are not generated. Declaring any of `CodingKeys`, `init(from:)` or `encode(to:)` leaves serialization entirely to you.
- The generated initializers live in an extension, so a struct keeps its memberwise initializer. A `public` or `package` struct, and a struct that declares initializers, gets a generated `init()` in its body (the implicit `init()` is internal and disappears next to declared initializers); an internal struct without initializers keeps the implicit one.
- An enum is cloned as a whole and listed without properties. It is serialized only if it declares `Codable` itself, and it gets `DefaultInitializable` only if it declares `init()`.
- The macro stores `static let componentIndex = registeredComponentIndex`. The index still comes from the registry at first access, so it cannot collide with a lazily assigned one. Declare your own `componentIndex` to opt out.

### Value types and diagnostics

`@Component` reports an error when it is applied to a class: components are value types, so use a struct or enum. The nexus also asserts once per component type, in debug builds, that a hand-written conformance is not a class.

A stored property spelled `Entity`, `Entity?`, `[Entity]`, `Set<Entity>` or `[Key: Entity]` is an error with a fix-it that replaces `Entity` by ``EntityIdentifier``. An ``Entity`` keeps its nexus alive and is not valid after a copy, a clone or a snapshot, while an identifier is a plain value that the clone context remaps. The macro sees syntax only: an `Entity` behind a typealias or in a nested type is not diagnosed and stays a convention.

### Registering, cloning and snapshots

```swift
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

Component types are registered automatically the first time an instance is assigned.
Register them explicitly before decoding snapshots that reference them.

A ``NexusSnapshot`` starts with a `formatVersion` and keeps the original entity identifiers.
Decoding creates new entities, remaps entity references to them through an ``EntityReferenceResolver``, and rejects snapshots written in a newer format version.
