//
//  EntityIdGenTests.swift
//
//
//  Created by Christian Treffs on 21.08.20.
//

import FirebladeECS
import Testing

/// Index 0 is reserved, so the first provided index is 1.
@Suite struct EntityIdGenTests {
    @Test func generatorDefaultInit() {
        let gen = DefaultEntityIdGenerator()
        #expect(gen.nextId() == 1)
    }

    @Test func generatorWithDefaultEmptyCollection() {
        let gen = DefaultEntityIdGenerator(startProviding: [])
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)
    }

    @Test func linearIncrement() {
        let gen = DefaultEntityIdGenerator()
        for i in 1..<1_000_000 {
            #expect(gen.nextId() == EntityIdentifier(index: UInt32(i), generation: 0))
        }
    }

    @Test func generateWithInitialIds() {
        let initialIds: [EntityIdentifier] = [2, 4, 11, 3, 1, 304]
        let gen = DefaultEntityIdGenerator(startProviding: initialIds)

        let generatedIds: [EntityIdentifier] = (0..<initialIds.count).map { _ in gen.nextId() }.reversed()
        #expect(initialIds == generatedIds)
        #expect(gen.nextId() == 5)
        #expect(gen.nextId() == 6)
        #expect(gen.nextId() == 7)
        #expect(gen.nextId() == 8)
        #expect(gen.nextId() == 9)
        #expect(gen.nextId() == 10)
        #expect(gen.nextId() == 12)

        for i in 13..<304 {
            #expect(gen.nextId() == EntityIdentifier(index: UInt32(i), generation: 0))
        }

        #expect(gen.nextId() == 305)
        #expect(gen.nextId() == 306)
    }

    @Test func generateWithSingleInitialId() {
        let gen = DefaultEntityIdGenerator(startProviding: [1])
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)
        #expect(gen.nextId() == 3)
    }

    @Test func generateWithInitialIdsNeverRepeatsInUseIds() {
        let gen = DefaultEntityIdGenerator(startProviding: [3, 1])
        let generatedIds = (0..<5).map { _ in gen.nextId() }
        #expect(generatedIds == [1, 3, 2, 4, 5])
    }

    @Test func generatorNeverProvidesReservedIndex() {
        let gen = DefaultEntityIdGenerator(startProviding: [.invalid, EntityIdentifier(index: 0, generation: 5)])
        #expect((0..<3).map { _ in gen.nextId() } == [1, 2, 3])

        gen.markUnused(entityId: .invalid)
        #expect(gen.nextId() == 4)
    }

    @Test func generatorKeepsGenerationsOfInitialIds() {
        let id = EntityIdentifier(index: 2, generation: 7)
        let gen = DefaultEntityIdGenerator(startProviding: [id])
        #expect(gen.nextId() == id)
        gen.markUnused(entityId: id)
        #expect(gen.nextId() == EntityIdentifier(index: 2, generation: 8))
    }

    @Test func generatorMarkUnused() {
        let gen = DefaultEntityIdGenerator()
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)
        #expect(gen.nextId() == 3)

        gen.markUnused(entityId: 2)

        // a recycled index is provided again, with the next generation
        #expect(gen.nextId() == EntityIdentifier(index: 2, generation: 1))
        #expect(gen.nextId() == 4)
        #expect(gen.nextId() == 5)

        gen.markUnused(entityId: 4)
        gen.markUnused(entityId: 1)

        #expect(gen.nextId() == EntityIdentifier(index: 1, generation: 1))
        #expect(gen.nextId() == EntityIdentifier(index: 4, generation: 1))

        gen.markUnused(entityId: EntityIdentifier(index: 4, generation: 1))

        #expect(gen.nextId() == EntityIdentifier(index: 4, generation: 2))
        #expect(gen.nextId() == 6)
        #expect(gen.nextId() == 7)
        #expect(gen.nextId() == 8)
        #expect(gen.nextId() == 9)
    }
}
