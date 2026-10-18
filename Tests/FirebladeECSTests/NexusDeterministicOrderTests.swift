//
//  NexusDeterministicOrderTests.swift
//  FirebladeECSTests
//

import Testing
@testable import FirebladeECS

/// Swift seeds `Dictionary` hashing per process, so any order taken from a dictionary changes between runs.
/// These tests expect identifier order, which a hash-seeded order of 256 entities matches only by chance.
@Suite struct NexusDeterministicOrderTests {
    private static let entityCount = 256

    @Test func familyCreatedAfterEntitiesHasDeterministicOrder() {
        let nexus = Nexus()
        let expected = (0..<Self.entityCount).map { index in
            nexus.createEntity(with: Position(x: index, y: index)).identifier
        }

        let family = nexus.family(requiresAll: Position.self)

        #expect(family.entities.map(\.identifier) == expected)
    }

    @Test func entitiesHaveDeterministicOrder() {
        let nexus = Nexus()
        let expected = (0..<Self.entityCount).map { _ in nexus.createEntity().identifier }

        #expect(nexus.makeEntitiesIterator().map(\.identifier) == expected)
    }
}
