//
//  NexusSnapshotTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

@testable import FirebladeECS
import Foundation
import Testing

final class SerialPosition: SerializableComponent, @unchecked Sendable {
    static let componentTypeName = "Position"
    var x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

final class SerialParent: SerializableComponent, @unchecked Sendable {
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

    @Test func encodedFormat() throws {
        let nexus = Nexus()
        let root = nexus.createEntity(with: SerialPosition(x: 1, y: 2))
        nexus.createEntity(with: SerialParent(parent: root))

        var encoder = makeEncoder()
        let data = try nexus.encodeSnapshot(using: &encoder, handling: .throwError)

        let json = String(decoding: data, as: UTF8.self)
        let expected = #"{"entities":[{"components":{"Position":{"x":1,"y":2}},"id":0},"#
            + #"{"components":{"Parent":{"parent":0}},"id":1}],"entityIdGenerator":{"nextFreshId":2,"recycled":[]},"formatVersion":2}"#
        #expect(json == expected)
    }

    @Test func roundTripRemapsEntityReferences() throws {
        let source = Nexus()
        let child = source.createEntity()
        let root = source.createEntity(with: SerialPosition(x: 3, y: 4))
        child.set(SerialParent(parent: root))

        var encoder = makeEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)

        let target = Nexus()
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

    @Test func unregisteredTypeThrowsAndRollsBack() throws {
        let source = Nexus()
        source.createEntity(with: SerialPosition(x: 1, y: 1))
        var encoder = makeEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)

        let target = Nexus()
        var decoder = JSONDecoder()
        #expect(throws: ComponentRegistryError.unknownTypeName("Position")) {
            try target.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(target.numEntities == 0)
    }

    @Test func nonSerializableComponents() throws {
        let nexus = Nexus()
        nexus.createEntity(with: SerialPosition(x: 1, y: 1), Position(x: 2, y: 2))

        #expect(throws: ComponentSerializationError.notSerializable(typeName: "FirebladeECSTests.Position")) {
            try nexus.makeSnapshot(handling: .throwError)
        }

        let snapshot = try nexus.makeSnapshot(handling: .skip)
        #expect(snapshot.members.count == 1)
        #expect(snapshot.members.first?.components.count == 1)
    }

    @Test func registeredNonSerializableTypeThrowsOnImport() throws {
        let nexus = Nexus()
        try nexus.register(RegisteredPosition.self)
        let data = Data(#"{"formatVersion":1,"entities":[{"id":0,"components":{"FirebladeECSTests.RegisteredPosition":{}}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.notSerializable(typeName: "FirebladeECSTests.RegisteredPosition")) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test func recordReportsSerializability() throws {
        let nexus = Nexus()
        #expect(try nexus.register(SerialPosition.self).isSerializable)
        #expect(try !nexus.register(RegisteredPosition.self).isSerializable)
    }

    @Test func newerFormatVersionThrowsWithoutSideEffects() throws {
        let nexus = Nexus()
        let data = Data(#"{"formatVersion":3,"entities":[{"id":0,"components":{}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.unsupportedFormatVersion(3)) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test func missingFormatVersionThrows() {
        let nexus = Nexus()
        let data = Data(#"{"entities":[{"id":0,"components":{}}]}"#.utf8)
        var decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try nexus.decodeSnapshot(from: data, using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test func snapshotKeepsOriginalEntityIdentifiers() throws {
        // Identity-preserving restores rely on the original identifiers, including gaps left by destroyed entities.
        let nexus = Nexus()
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
        let expected = #"{"entities":[{"components":{"Position":{"x":0,"y":0}},"id":0},{"components":{},"id":2},"#
            + #"{"components":{"Position":{"x":3,"y":3}},"id":3}],"entityIdGenerator":{"nextFreshId":4,"recycled":[1]},"formatVersion":2}"#
        #expect(json == expected)
    }
}
