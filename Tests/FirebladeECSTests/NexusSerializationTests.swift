//
//  NexusSerializationTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.26.
//

@testable import FirebladeECS
import Foundation
import Testing

final class SerialTarget: SerializableComponent, @unchecked Sendable {
    static let componentTypeName = "Target"
    var target: EntityIdentifier

    init(target: EntityIdentifier) {
        self.target = target
    }
}

final class SerialHealth: SerializableComponent, @unchecked Sendable {
    static let componentTypeName = "Health"
    static let componentTypeNameAliases = ["OldHealth"]
    var value: Int

    init(value: Int) {
        self.value = value
    }
}

final class SerialConflictingHealth: SerializableComponent, @unchecked Sendable {
    static let componentTypeName = "ConflictingHealth"
    static let componentTypeNameAliases = ["Health"]
    var value = 0
}

/// A scene file wrapping a nexus, as a game would store it.
struct SerialScene: Codable {
    var name: String
    var nexus: Nexus
}

/// An entity identifier generator that cannot be persisted.
struct NonPersistableEntityIdGenerator: EntityIdentifierGenerator, @unchecked Sendable {
    final class Storage {
        var stack: [EntityIdentifier]
        var next: EntityIdentifier.Identifier = 0

        init(stack: [EntityIdentifier]) {
            self.stack = stack
        }
    }

    let storage: Storage

    init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier {
        storage = Storage(stack: Array(initialEntityIds))
        storage.next = (initialEntityIds.map(\.id).max() ?? 0) + (initialEntityIds.isEmpty ? 0 : 1)
    }

    func nextId() -> EntityIdentifier {
        if let id = storage.stack.popLast() {
            return id
        }
        defer { storage.next += 1 }
        return EntityIdentifier(storage.next)
    }

    func markUnused(entityId: EntityIdentifier) {
        storage.stack.append(entityId)
    }
}

/// Records the events of a nexus.
final class SerialEventRecorder: NexusEventDelegate, @unchecked Sendable {
    var createdEntities: [EntityIdentifier] = []
    var addedComponents = 0

    func nexusEvent(_ event: NexusEvent) {
        if let created = event as? EntityCreated {
            createdEntities.append(created.entityId)
        } else if event is ComponentAdded {
            addedComponents += 1
        }
    }

    func nexusNonFatalError(_: String) {}
}

/// A Codable format a scene can be stored in.
///
/// The closures only create stateless coders, so sharing a format between tests is safe.
struct SerialFormat: CustomTestStringConvertible, @unchecked Sendable {
    let testDescription: String
    let encode: (_ value: any Encodable, _ userInfo: [CodingUserInfoKey: any Sendable]) throws -> Data
    let decodeScene: (_ data: Data, _ userInfo: [CodingUserInfoKey: any Sendable]) throws -> SerialScene
    let encodeSnapshot: (_ nexus: Nexus) throws -> Data
    let restoreSnapshot: (_ data: Data, _ nexus: Nexus) throws -> Void

    static func make<Encoder: TopLevelEncoder, Decoder: TopLevelDecoder>(
        _ name: String,
        encoder makeEncoder: @escaping () -> Encoder,
        decoder makeDecoder: @escaping () -> Decoder
    ) -> SerialFormat
        where Encoder.Output == Data, Decoder.Input == Data
    {
        SerialFormat(
            testDescription: name,
            encode: { value, userInfo in
                var encoder = makeEncoder()
                // The coders' user info value type is `Any` or `any Sendable`, depending on the SDK.
                encoder.userInfo = userInfo.compactMapValues { $0 as? Encoder.UserInfoValue }
                return try encoder.encode(value)
            },
            decodeScene: { data, userInfo in
                var decoder = makeDecoder()
                decoder.userInfo = userInfo.compactMapValues { $0 as? Decoder.UserInfoValue }
                return try decoder.decode(SerialScene.self, from: data)
            },
            encodeSnapshot: { nexus in
                var encoder = makeEncoder()
                return try nexus.encodeSnapshot(using: &encoder, handling: .throwError)
            },
            restoreSnapshot: { data, nexus in
                var decoder = makeDecoder()
                try nexus.restoreSnapshot(from: data, using: &decoder)
            }
        )
    }

    static let all: [SerialFormat] = [
        .make("JSON", encoder: { JSONEncoder() }, decoder: { JSONDecoder() }),
        .make("XML property list", encoder: {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            return encoder
        }, decoder: { PropertyListDecoder() }),
        .make("Binary property list", encoder: {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            return encoder
        }, decoder: { PropertyListDecoder() })
    ]
}

@Suite struct NexusSerializationTests {
    static let componentTypes: [any SerializableComponent.Type] = [SerialPosition.self, SerialParent.self, SerialTarget.self, SerialHealth.self]

    /// Builds a nexus with gaps in its entity identifiers, entity references and a shared component instance.
    private func makeScene() -> (nexus: Nexus, root: Entity, child: Entity, sibling: Entity) {
        let nexus = Nexus()
        let root = nexus.createEntity(with: SerialPosition(x: 1, y: 2))
        let destroyed = nexus.createEntity()
        let child = nexus.createEntity(with: SerialParent(parent: root), SerialTarget(target: root.identifier))
        let alsoDestroyed = nexus.createEntity()
        let sibling = nexus.createEntity(with: SerialHealth(value: 7))
        nexus.destroy(entity: destroyed)
        nexus.destroy(entity: alsoDestroyed)
        let shared = SerialPosition(x: 5, y: 6)
        child.set(shared)
        sibling.set(shared)
        return (nexus, root, child, sibling)
    }

    private func expectRestored(_ restored: Nexus, matches source: (nexus: Nexus, root: Entity, child: Entity, sibling: Entity)) throws {
        #expect(restored.numEntities == source.nexus.numEntities)
        #expect(restored.numComponents == source.nexus.numComponents)
        #expect(Set(restored.makeEntitiesIterator().map(\.identifier)) == [source.root.identifier, source.child.identifier, source.sibling.identifier])

        let root = restored.entity(from: source.root.identifier)
        let child = restored.entity(from: source.child.identifier)
        let sibling = restored.entity(from: source.sibling.identifier)
        #expect(try #require(root.get(SerialPosition.self)).x == 1)
        #expect(try #require(child.get(SerialParent.self)).parent == root)
        #expect(try #require(child.get(SerialTarget.self)).target == root.identifier)
        #expect(try #require(sibling.get(SerialHealth.self)).value == 7)
        let shared = try #require(child.get(SerialPosition.self))
        #expect(shared === sibling.get(SerialPosition.self))
        #expect(shared.x == 5)
        #expect(restored.family(requires: SerialPosition.self).count == 3)

        // The restored generator provides the identifiers the source nexus would have provided next.
        for _ in 0 ..< 3 {
            #expect(restored.createEntity().identifier == source.nexus.createEntity().identifier)
        }
    }

    @Test(arguments: SerialFormat.all)
    func restoreSnapshotPreservesIdentity(format: SerialFormat) throws {
        let source = makeScene()
        let data = try format.encodeSnapshot(source.nexus)

        let restored = Nexus()
        try restored.register(Self.componentTypes.map { $0 as any RegistrableComponent.Type })
        try format.restoreSnapshot(data, restored)

        try expectRestored(restored, matches: source)
    }

    @Test(arguments: SerialFormat.all)
    func nexusCodableRoundTrip(format: SerialFormat) throws {
        let source = makeScene()
        let data = try format.encode(SerialScene(name: "Level 1", nexus: source.nexus), [:])

        let scene = try format.decodeScene(data, [
            .nexusComponentTypes: Self.componentTypes,
            .nexusEntityResolver: EntityReferenceResolver(mapping: [:])
        ])

        #expect(scene.name == "Level 1")
        try expectRestored(scene.nexus, matches: source)
    }

    @Test func repeatedRoundTripsAreStable() throws {
        // Sorted keys make the output deterministic, e.g. for scene files under version control.
        let format = SerialFormat.make("Sorted JSON", encoder: {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return encoder
        }, decoder: { JSONDecoder() })
        let first = try format.encode(SerialScene(name: "Level", nexus: makeScene().nexus), [:])
        let userInfo: [CodingUserInfoKey: any Sendable] = [
            .nexusComponentTypes: Self.componentTypes,
            .nexusEntityResolver: EntityReferenceResolver(mapping: [:])
        ]
        let second = try format.encode(format.decodeScene(first, userInfo), [:])
        let third = try format.encode(format.decodeScene(second, userInfo), [:])
        #expect(second == third)
        #expect(try format.decodeScene(first, userInfo).nexus.numComponents == format.decodeScene(third, userInfo).nexus.numComponents)
    }

    @Test func restoreEmitsEvents() throws {
        let source = makeScene()
        var encoder = JSONEncoder()
        let data = try source.nexus.encodeSnapshot(using: &encoder, handling: .throwError)

        let recorder = SerialEventRecorder()
        let restored = Nexus()
        restored.delegate = recorder
        try restored.register(Self.componentTypes.map { $0 as any RegistrableComponent.Type })
        var decoder = JSONDecoder()
        try restored.restoreSnapshot(from: data, using: &decoder)

        #expect(recorder.createdEntities == [source.root.identifier, source.child.identifier, source.sibling.identifier])
        #expect(recorder.addedComponents == source.nexus.numComponents)
    }

    @Test func nexusEncodingThrowsForNonSerializableComponentsByDefault() throws {
        let nexus = Nexus()
        nexus.createEntity(with: SerialPosition(x: 1, y: 1), Position(x: 2, y: 2))

        #expect(throws: ComponentSerializationError.notSerializable(typeName: "FirebladeECSTests.Position")) {
            try JSONEncoder().encode(nexus)
        }

        let encoder = JSONEncoder()
        encoder.userInfo[.nexusNonSerializableComponentHandling] = NonSerializableComponentHandling.skip
        let decoder = JSONDecoder()
        decoder.userInfo[.nexusComponentTypes] = Self.componentTypes
        let restored = try decoder.decode(Nexus.self, from: encoder.encode(nexus))
        #expect(restored.numComponents == 1)
    }

    @Test func nexusDecodingWithoutComponentTypesThrows() throws {
        let data = try JSONEncoder().encode(makeScene().nexus)
        #expect(throws: ComponentRegistryError.self) {
            try JSONDecoder().decode(Nexus.self, from: data)
        }
    }

    @Test func renamedTypeLoadsByAlias() throws {
        let data = Data(#"{"formatVersion":1,"entities":[{"id":0,"components":{"OldHealth":{"value":3}}}]}"#.utf8)
        let nexus = Nexus()
        try nexus.register(SerialHealth.self)
        var decoder = JSONDecoder()
        try nexus.restoreSnapshot(from: data, using: &decoder)
        #expect(nexus.entity(from: 0).get(SerialHealth.self)?.value == 3)
        #expect(nexus.componentType(named: "OldHealth")?.typeName == "Health")

        let snapshot = try nexus.makeSnapshot(handling: .throwError)
        #expect(snapshot.members.first.map { type(of: $0.components[0]).componentTypeName } == "Health")
    }

    @Test func conflictingAliasThrows() throws {
        let nexus = Nexus()
        try nexus.register(SerialHealth.self)
        #expect(throws: ComponentRegistryError.duplicateTypeName("Health")) {
            try nexus.register(SerialConflictingHealth.self)
        }
        #expect(!nexus.isRegistered(SerialConflictingHealth.self))
    }

    @Test func formatVersion1RestoresIdentity() throws {
        let data = Data(#"{"formatVersion":1,"entities":[{"id":0,"components":{"Health":{"value":1}}},{"id":2,"components":{"Health":{"value":2}}}]}"#.utf8)
        let nexus = Nexus()
        try nexus.register(SerialHealth.self)
        var decoder = JSONDecoder()
        try nexus.restoreSnapshot(from: data, using: &decoder)

        #expect(nexus.entity(from: 2).get(SerialHealth.self)?.value == 2)
        #expect(nexus.createEntity().identifier == 1)
        #expect(nexus.createEntity().identifier == 3)
    }

    @Test func restoreIntoNonEmptyNexusThrowsWithoutSideEffects() throws {
        var encoder = JSONEncoder()
        let data = try makeScene().nexus.encodeSnapshot(using: &encoder, handling: .throwError)
        let nexus = Nexus()
        let existing = nexus.createEntity(with: SerialHealth(value: 1))
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.nexusNotEmpty) {
            try nexus.restoreSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 1)
        #expect(existing.get(SerialHealth.self)?.value == 1)
    }

    @Test func failedRestoreRollsBack() throws {
        var encoder = JSONEncoder()
        let data = try makeScene().nexus.encodeSnapshot(using: &encoder, handling: .throwError)
        let nexus = Nexus()
        try nexus.register(SerialPosition.self)
        var decoder = JSONDecoder()
        #expect(throws: ComponentRegistryError.unknownTypeName("Parent")) {
            try nexus.restoreSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
        #expect(nexus.createEntity().identifier == 0)
    }

    @Test func missingSharedOwnerThrows() throws {
        let data = Data(#"{"formatVersion":2,"entities":[{"id":0,"components":{}},{"id":1,"components":{},"sharedComponents":{"Health":0}}]}"#.utf8)
        let nexus = Nexus()
        try nexus.register(SerialHealth.self)
        var decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try nexus.restoreSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test func duplicateEntityIdentifierThrows() throws {
        let data = Data(#"{"formatVersion":2,"entities":[{"id":0,"components":{}},{"id":0,"components":{}}]}"#.utf8)
        let nexus = Nexus()
        var decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test func nonPersistableGeneratorKeepsIdentity() throws {
        let source = Nexus()
        source.entityIdGenerator = NonPersistableEntityIdGenerator(startProviding: [])
        source.createEntity()
        let kept = source.createEntity(with: SerialHealth(value: 4))
        source.destroy(entity: source.entity(from: 0))
        var encoder = JSONEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)
        #expect(!String(decoding: data, as: UTF8.self).contains("entityIdGenerator"))

        let restored = Nexus()
        restored.entityIdGenerator = NonPersistableEntityIdGenerator(startProviding: [])
        try restored.register(SerialHealth.self)
        var decoder = JSONDecoder()
        try restored.restoreSnapshot(from: data, using: &decoder)
        #expect(restored.entity(from: kept.identifier).get(SerialHealth.self)?.value == 4)
        #expect(restored.entityIdGenerator is NonPersistableEntityIdGenerator)
    }

    @Test func generatorStateIsIgnoredForNonPersistableGenerator() throws {
        var encoder = JSONEncoder()
        let data = try makeScene().nexus.encodeSnapshot(using: &encoder, handling: .throwError)
        let restored = Nexus()
        restored.entityIdGenerator = NonPersistableEntityIdGenerator(startProviding: [])
        try restored.register(Self.componentTypes.map { $0 as any RegistrableComponent.Type })
        var decoder = JSONDecoder()
        try restored.restoreSnapshot(from: data, using: &decoder)
        #expect(restored.numEntities == 3)
        #expect(restored.entityIdGenerator is NonPersistableEntityIdGenerator)
    }

    @Test func generatorStateRejectsInvalidRecycledIdentifiers() {
        let data = Data(#"{"nextFreshId":2,"recycled":[5]}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(LinearIncrementingEntityIdGenerator.self, from: data)
        }
    }
}
