//
//  NexusIterationOrderTests.swift
//  FirebladeECSTests
//

import Testing
@testable import FirebladeECS

/// Swift seeds `Dictionary` hashing per process, so any order taken from a dictionary changes between runs.
/// These tests pin iteration orders to ascending entity identifiers instead.
@Suite struct NexusIterationOrderTests {
    private static let entityCount = 256

    @Test func familyCreatedAfterEntitiesIteratesInIdentifierOrder() {
        let nexus = Nexus()
        let expected = (0..<Self.entityCount).map { index in
            nexus.createEntity(with: Position(x: index, y: index)).identifier
        }

        let family = nexus.family(requiresAll: Position.self)

        #expect(family.entities.map(\.identifier) == expected)
    }

    @Test func entitiesIterateInIdentifierOrder() {
        let nexus = Nexus()
        let expected = (0..<Self.entityCount).map { _ in nexus.createEntity().identifier }

        #expect(nexus.makeEntitiesIterator().map(\.identifier) == expected)
    }
}
