//
//  SnapshotV1CompatTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Foundation
import Testing

/// Snapshots written by FirebladeECS 1.x (format versions 1 and 2) still load, their identifiers decode with generation 0.
@Suite struct SnapshotV1CompatTests {
    static let componentTypes: [any RegistrableComponent.Type] = [SerialPosition.self, SerialParent.self, SerialTarget.self, SerialHealth.self]

    /// Format version 1: no generator state, no shared components. Index 0 is used and index 1 is a gap.
    static let version1 = #"""
    {"formatVersion":1,"entities":[
      {"id":0,"components":{"Position":{"x":1,"y":2}}},
      {"id":2,"components":{"Health":{"value":9},"Parent":{"parent":0},"Target":{"target":0}}}
    ]}
    """#

    /// Format version 2: generator state with recycled indices, a shared component and references to index 0.
    static let version2 = #"""
    {"formatVersion":2,"entityIdGenerator":{"nextFreshId":4,"recycled":[1,3]},"entities":[
      {"id":0,"components":{"Position":{"x":1,"y":2}}},
      {"id":2,"components":{"Parent":{"parent":0},"Target":{"target":0}},"sharedComponents":{"Position":0}}
    ]}
    """#

    private func makeNexus(_ storage: Nexus.StorageKind) throws -> Nexus {
        let nexus = Nexus(storage: storage)
        try nexus.register(Self.componentTypes)
        return nexus
    }

    private func restore(_ json: String, into nexus: Nexus) throws {
        var decoder = JSONDecoder()
        try nexus.restoreSnapshot(from: Data(json.utf8), using: &decoder)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version1KeepsIdentifiersExceptReservedIndex(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        try restore(Self.version1, into: nexus)

        #expect(nexus.numEntities == 2)
        let kept = try #require(nexus.entity(EntityIdentifier(index: 2, generation: 0)))
        #expect(kept.get(SerialHealth.self)?.value == 9)

        // Index 0 is reserved now: its entity got the lowest free identifier and the references to it were remapped.
        let replacement = try #require(nexus.entity(EntityIdentifier(index: 1, generation: 0)))
        #expect(replacement.get(SerialPosition.self)?.x == 1)
        #expect(kept.get(SerialParent.self)?.parent == replacement)
        #expect(kept.get(SerialTarget.self)?.target == replacement.identifier)
        #expect(nexus.createEntity().identifier == EntityIdentifier(index: 3, generation: 0))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version2RestoresGeneratorStateWithGenerationZero(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        try restore(Self.version2, into: nexus)

        let kept = try #require(nexus.entity(EntityIdentifier(index: 2, generation: 0)))
        // the recycled indices 1 and 3 are provided in last out order; the entity of index 0 took 3
        let replacement = try #require(nexus.entity(EntityIdentifier(index: 3, generation: 0)))
        #expect(kept.get(SerialPosition.self) == replacement.get(SerialPosition.self))
        #expect(kept.get(SerialParent.self)?.parent == replacement)
        #expect(kept.get(SerialTarget.self)?.target == replacement.identifier)

        #expect(nexus.createEntity().identifier == EntityIdentifier(index: 1, generation: 0))
        #expect(nexus.createEntity().identifier == EntityIdentifier(index: 4, generation: 0))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version2ImportsAsNewEntities(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        nexus.createEntity()
        var decoder = JSONDecoder()
        let mapping = try nexus.decodeSnapshot(from: Data(Self.version2.utf8), using: &decoder)

        #expect(nexus.numEntities == 3)
        let imported = try #require(mapping[EntityIdentifier(index: 2, generation: 0)])
        let importedZero = try #require(mapping[.invalid])
        #expect(imported.get(SerialParent.self)?.parent == importedZero)
        #expect(imported.get(SerialTarget.self)?.target == importedZero.identifier)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func unknownLegacyFieldsAreIgnoredAndOldCurrentVersionsEncodeAsVersion3(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        try restore(Self.version2, into: nexus)
        var encoder = JSONEncoder()
        let data = try nexus.encodeSnapshot(using: &encoder, handling: .throwError)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains(#""formatVersion":3"#))
        #expect(json.contains("recycledIds"))
        #expect(!json.contains(#""recycled":"#))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version3RoundTripKeepsGenerations(_ storage: Nexus.StorageKind) throws {
        let source = try makeNexus(storage)
        let first = source.createEntity(with: SerialPosition(x: 1, y: 1))
        source.destroy(entity: first)
        let reused = source.createEntity(with: SerialPosition(x: 2, y: 2))
        let other = source.createEntity(with: SerialParent(parent: reused))
        let doomed = source.createEntity()
        source.destroy(entity: doomed)
        #expect(reused.identifier == EntityIdentifier(index: 1, generation: 1))

        var encoder = JSONEncoder()
        let data = try source.encodeSnapshot(using: &encoder, handling: .throwError)
        #expect(String(decoding: data, as: UTF8.self).contains(#""formatVersion":3"#))

        let restored = try makeNexus(storage)
        var decoder = JSONDecoder()
        try restored.restoreSnapshot(from: data, using: &decoder)

        #expect(restored.isAlive(reused.identifier))
        #expect(!restored.isAlive(first.identifier))
        #expect(restored.entity(first.identifier) == nil)
        let restoredOther = try #require(restored.entity(other.identifier))
        #expect(restoredOther.get(SerialParent.self)?.parent.identifier == reused.identifier)
        // the restored generator continues exactly like the source: the destroyed slot returns with a higher generation
        #expect(restored.createEntity().identifier == source.createEntity().identifier)
        #expect(restored.createEntity().identifier == source.createEntity().identifier)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version3RejectsReservedIndex(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        let json = #"{"formatVersion":3,"entities":[{"id":4294967296,"components":{}}]}"#
        #expect(throws: DecodingError.self) {
            try restore(json, into: nexus)
        }
        #expect(nexus.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func version3IdentifierIsTheRawValue(_ storage: Nexus.StorageKind) throws {
        let nexus = try makeNexus(storage)
        let json = #"{"formatVersion":3,"entities":[{"id":8589934595,"components":{"Health":{"value":5}}}]}"#
        try restore(json, into: nexus)
        let entity = try #require(nexus.entity(EntityIdentifier(index: 3, generation: 2)))
        #expect(entity.get(SerialHealth.self)?.value == 5)
        #expect(entity.identifier.rawValue == 8_589_934_595)
    }
}
