# Saving and Loading Scenes

Store a whole ``Nexus`` on disk and load it again with the same entities, components and entity identifiers.

## Overview

A nexus encodes as a ``NexusSnapshot``: every entity with its original identifier, the components conforming to ``SerializableComponent``, and the state of the entity identifier generator.
The snapshot works with any `Codable` format, such as JSON, property lists or YAML.

### Make components serializable

Conform each component you want to persist to ``SerializableComponent``, or annotate it with `@Component` (see <doc:ComponentMacro>).
Give each persisted type an explicit, stable name. The default name is the fully qualified Swift type name, which changes when you rename the type or its module:

```swift
final class Position: SerializableComponent {
    static let componentTypeName = "Position"
    var x: Double
    var y: Double
}
```

If you rename a type later, list its former names, so existing scene files keep loading:

```swift
final class Health: SerializableComponent {
    static let componentTypeName = "Health"
    static let componentTypeNameAliases = ["HitPoints"]
    var value: Int
}
```

Components referencing other entities can store an ``Entity`` or an ``EntityIdentifier``. Both are restored correctly.

### Save and load a nexus with Codable

``Nexus`` conforms to `Codable`, so it can be part of your own scene type:

```swift
struct Scene: Codable {
    var name: String
    var nexus: Nexus
}

let data = try JSONEncoder().encode(Scene(name: "Level 1", nexus: nexus))

let decoder = JSONDecoder()
decoder.userInfo[.nexusComponentTypes] = [Position.self, Health.self, Parent.self] as [any SerializableComponent.Type]
decoder.userInfo[.nexusEntityResolver] = EntityReferenceResolver(mapping: [:]) // needed for `Entity` properties
let scene = try decoder.decode(Scene.self, from: data)
```

- Encoding throws ``ComponentSerializationError/notSerializable(typeName:)`` for components that are not serializable.
  To leave runtime-only components out instead, set `encoder.userInfo[.nexusNonSerializableComponentHandling]` to ``NonSerializableComponentHandling/skip``.
- Decoding needs all component types of the scene in `userInfo[.nexusComponentTypes]`. Unknown names throw ``ComponentRegistryError/unknownTypeName(_:)``.
- The decoded nexus has the same entity identifiers and creates new entities with the identifiers the original nexus would have used next.

### Load into an existing nexus

To keep a configured nexus, for example one with a delegate, families or a custom generator, use the snapshot API directly:

```swift
var encoder = JSONEncoder()
let data = try nexus.encodeSnapshot(using: &encoder, handling: .throwError)

let restored = Nexus()
try restored.register([Position.self, Health.self, Parent.self])
var decoder = JSONDecoder()
try restored.restoreSnapshot(from: data, using: &decoder)
```

- ``Nexus/restoreSnapshot(from:using:)`` keeps the entity identifiers. It requires a nexus without entities and emits the usual entity and component events.
- ``Nexus/decodeSnapshot(from:using:)`` adds the snapshot as new entities to a populated nexus, for example for prefabs, and returns the mapping from saved to new identifiers.

Both roll back all changes if decoding fails.

### Use other formats

The snapshot API accepts any coder conforming to ``TopLevelEncoder`` and ``TopLevelDecoder``.
`JSONEncoder` and `PropertyListEncoder` and their decoders conform out of the box.
For other formats, add the conformance in your project. For example, with [Yams](https://github.com/jpsim/Yams):

```swift
import Yams

struct YAMLSceneEncoder: TopLevelEncoder {
    var userInfo: [CodingUserInfoKey: UserInfoValue] = [:]
    func encode<T: Encodable>(_ value: T) throws -> String {
        try YAMLEncoder().encode(value, userInfo: userInfo)
    }
}

struct YAMLSceneDecoder: TopLevelDecoder {
    var userInfo: [CodingUserInfoKey: UserInfoValue] = [:]
    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        try YAMLDecoder().decode(type, from: yaml, userInfo: userInfo)
    }
}
```

`Nexus: Codable` works with any `Codable` coder directly.

For deterministic output, for example for scene files under version control, sort the keys, e.g. with `JSONEncoder.OutputFormatting.sortedKeys`.

### What a snapshot contains

- Every entity, including entities without components, with its original identifier.
- Every serializable component. A component instance shared by several entities is stored once and shared again after loading.
- The entity identifier generator state, if the generator conforms to ``PersistableEntityIdentifierGenerator``. ``LinearIncrementingEntityIdGenerator`` does.

Not contained are components that are not serializable, families (they are derived from the components) and the nexus delegate.

The format is versioned by ``NexusSnapshot/formatVersion``. Newer versions of FirebladeECS keep loading older snapshots and reject snapshots written by a newer version.
