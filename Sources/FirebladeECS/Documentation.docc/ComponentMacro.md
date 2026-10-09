# Generating components with the component macro

Implement registration, cloning, snapshots and inspection for a component from its stored properties.

## Overview

The optional `FirebladeECSMacros` product provides the `@Component` macro.
It turns a `final class` into a component and implements a set of component protocols from its stored properties, so you don't have to write that code by hand:

| Protocol | Generated | Enables |
| --- | --- | --- |
| ``RegistrableComponent`` | stable `componentTypeName` | `nexus.register(_:)`, `nexus.registeredComponentTypes`, `nexus.componentType(named:)` |
| ``CloneableComponent`` | `init(cloning:context:)`, `clone(context:)` | `entity.clone()`, `nexus.clone(entities:)`, `nexus.clone(into:)` |
| ``SerializableComponent`` | `CodingKeys`, `init(from:)`, `encode(to:)` | `nexus.encodeSnapshot(using:handling:)`, `nexus.decodeSnapshot(from:using:)` |
| ``InspectableComponent`` | `componentProperties` | generic inspection, e.g. in editors |
| ``DefaultInitializable`` | `init()` if every stored property has a default value | key path assignment, state machines |

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
```

- The stable type name defaults to the fully qualified type name. Declare `static let componentTypeName` to override it.
- `@Component(excluding:)` takes a `ComponentMacroFeatures` set: `.cloneable`, `.serializable`, `.inspectable` and `.defaultInit`. Registration is always implemented.
- `@ComponentIgnored` keeps a stored property out of serialization and inspection. Ignored properties are still cloned and need a default value.
- Serialized properties need an explicit type annotation. `let` constants with an initial value are not serialized.
- Members you declare yourself are not generated. Declaring any of `CodingKeys`, `init(from:)` or `encode(to:)` leaves serialization entirely to you.
- The generated initializers are designated initializers, so the class no longer gets an implicit `init()`. Keep `.defaultInit` enabled or declare your own initializers.

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
