//
//  EntityCodingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECS
import Foundation
import Testing

@Suite struct EntityCodingTests {
    @Test func entityIdentifierRoundTrip() throws {
        let identifier = EntityIdentifier(42)
        let data = try JSONEncoder().encode(identifier)
        #expect(String(decoding: data, as: UTF8.self) == "42")
        #expect(try JSONDecoder().decode(EntityIdentifier.self, from: data) == identifier)
    }

    @Test func entityEncodesAsIdentifier() throws {
        let nexus = Nexus()
        nexus.createEntity()
        let entity = nexus.createEntity()
        let data = try JSONEncoder().encode(entity)
        #expect(String(decoding: data, as: UTF8.self) == "\(entity.identifier.id)")
    }

    @Test func entityDecodesThroughResolver() throws {
        let target = Nexus()
        let first = target.createEntity()
        let second = target.createEntity()
        let resolver = EntityReferenceResolver(nexus: target, mapping: [7: second.identifier, 8: first.identifier])
        let decoder = JSONDecoder()
        decoder.userInfo[.nexusEntityResolver] = resolver

        let entities = try decoder.decode([Entity].self, from: Data("[7, 8]".utf8))
        #expect(entities == [second, first])
    }

    @Test func entityDecodingWithoutResolverThrows() {
        #expect(throws: EntityReferenceError.missingResolver) {
            try JSONDecoder().decode(Entity.self, from: Data("1".utf8))
        }
    }

    @Test func entityDecodingUnmappedIdentifierThrows() {
        let decoder = JSONDecoder()
        decoder.userInfo[.nexusEntityResolver] = EntityReferenceResolver(nexus: Nexus(), mapping: [:])
        #expect(throws: EntityReferenceError.unresolved(3)) {
            try decoder.decode(Entity.self, from: Data("3".utf8))
        }
    }
}
