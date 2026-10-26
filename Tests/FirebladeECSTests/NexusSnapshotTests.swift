//
//  NexusSnapshotTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

@testable import FirebladeECS
import Foundation
import Testing

struct SerialPosition: Equatable, SerializableComponent, Sendable {
    static let componentTypeName = "Position"
    var x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

struct SerialParent: Equatable, SerializableComponent, Sendable {
    static let componentTypeName = "Parent"
    var parent: Entity

    init(parent: Entity) {
        self.parent = parent
    }
}

@Suite struct NexusSnapshotTests {
    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    @Test(arguments: Nexus.StorageKind.allCases) func encodedFormat(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let root = nexus.createEntity(with: SerialPosition(x: 1, y: 2))
        nexus.createEntity(with: SerialParent(parent: root))

        var encoder = makeEncoder()
        let data = try nexus.encodeSnapshot(using: &encoder, handling: .throwError)

        let json = String(decoding: data, as: UTF8.self)
        let expected = #"{"entities":[{"components":{"Position":{"x":1,"y":2}},"id":1},"#
            + #"{"components":{"Parent":{"parent":1}},"id":2}],"entityIdGenerator":{"nextFreshId":3,"recycledIds":[]},"formatVersion":3}"#
        #expect(json == expected)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func roundTripRemapsEntityReferences(_ storage: Nexus.StorageKind) throws {
        let source = Nexus(storage: storage)
        let child = source.createEntity()
        let root = source.createEntity(with: SerialPosition(x: 3, y: 4))
        child.set(SerialParent(parent: root))

        var encoder = makeEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)

        let target = Nexus(storage: storage)
        target.createEntity()
        try target.register([SerialPosition.self, SerialParent.self])
        var decoder = JSONDecoder()
        let mapping = try target.decodeSnapshot(from: data, using: &decoder)

        #expect(target.numEntities == 3)
        let importedRoot = try #require(mapping[root.identifier])
        let importedChild = try #require(mapping[child.identifier])
        #expect(importedRoot.identifier != root.identifier)
        let position = try #require(importedRoot.get(SerialPosition.self))
        #expect(position.x == 3)
        #expect(position.y == 4)
        #expect(try #require(importedChild.get(SerialParent.self)).parent == importedRoot)
        #expect(target.family(requires: SerialPosition.self).count == 1)
        #expect(decoder.userInfo[.nexusEntityResolver] == nil)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func unregisteredTypeThrowsAndRollsBack(_ storage: Nexus.StorageKind) throws {
        let source = Nexus(storage: storage)
        source.createEntity(with: SerialPosition(x: 1, y: 1))
        var encoder = makeEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)

        let target = Nexus(storage: storage)
        var decoder = JSONDecoder()
        #expect(throws: ComponentRegistryError.unknownTypeName("Position")) {
            try target.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(target.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func nonSerializableComponents(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        nexus.createEntity(with: SerialPosition(x: 1, y: 1), Position(x: 2, y: 2))

        #expect(throws: ComponentSerializationError.notSerializable(typeName: "FirebladeECSTests.Position")) {
            try nexus.makeSnapshot(handling: .throwError)
        }

        let snapshot = try nexus.makeSnapshot(handling: .skip)
        #expect(snapshot.members.count == 1)
        #expect(snapshot.members.first?.components.count == 1)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func registeredNonSerializableTypeThrowsOnImport(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        try nexus.register(RegisteredPosition.self)
        let data = Data(#"{"formatVersion":1,"entities":[{"id":0,"components":{"FirebladeECSTests.RegisteredPosition":{}}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.notSerializable(typeName: "FirebladeECSTests.RegisteredPosition")) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func recordReportsSerializability(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        #expect(try nexus.register(SerialPosition.self).isSerializable)
        #expect(try !nexus.register(RegisteredPosition.self).isSerializable)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func newerFormatVersionThrowsWithoutSideEffects(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let data = Data(#"{"formatVersion":4,"entities":[{"id":0,"components":{}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.unsupportedFormatVersion(4)) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func missingFormatVersionThrows(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let data = Data(#"{"entities":[{"id":0,"components":{}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func snapshotKeepsOriginalEntityIdentifiers(_ storage: Nexus.StorageKind) throws {
        // Identity-preserving restores rely on the original identifiers, including gaps left by destroyed entities.
        let nexus = Nexus(storage: storage)
        let first = nexus.createEntity(with: SerialPosition(x: 0, y: 0))
        let destroyed = nexus.createEntity()
        let third = nexus.createEntity()
        let fourth = nexus.createEntity(with: SerialPosition(x: 3, y: 3))
        nexus.destroy(entity: destroyed)

        let snapshot = try nexus.makeSnapshot(handling: .throwError)
        #expect(snapshot.members.map(\.identifier) == [first.identifier, third.identifier, fourth.identifier])
        #expect(snapshot.members.map(\.components.count) == [1, 0, 1])

        var encoder = makeEncoder()
        let data = try nexus.encodeSnapshot(using: &encoder, handling: .throwError)
        let json = String(decoding: data, as: UTF8.self)
        let expected = #"{"entities":[{"components":{"Position":{"x":0,"y":0}},"id":1},{"components":{},"id":3},"#
            + #"{"components":{"Position":{"x":3,"y":3}},"id":4}],"entityIdGenerator":{"nextFreshId":5,"recycledIds":[4294967298]},"formatVersion":3}"#
        #expect(json == expected)
    }
}
