//
//  EntityIdGenTests.swift
//
//
//  Created by Christian Treffs on 21.08.20.
//

import FirebladeECS
import Testing

@Suite struct EntityIdGenTests {
    @Test func generatorDefaultInit() {
        let gen = DefaultEntityIdGenerator()
        #expect(gen.nextId() == 0)
    }

    @Test func generatorWithDefaultEmptyCollection() {
        let gen = DefaultEntityIdGenerator(startProviding: [])
        #expect(gen.nextId() == 0)
        #expect(gen.nextId() == 1)
    }

    @Test func linearIncrement() {
        let gen = DefaultEntityIdGenerator()
        for i in 0..<1_000_000 {
            #expect(gen.nextId() == EntityIdentifier(index: UInt32(i), generation: 1))
        }
    }

    @Test func generateWithInitialIds() {
        let initialIds: [EntityIdentifier] = [2, 4, 11, 3, 0, 304]
        let gen = DefaultEntityIdGenerator(startProviding: initialIds)

        let generatedIds: [EntityIdentifier] = (0..<initialIds.count).map { _ in gen.nextId() }.reversed()
        #expect(initialIds == generatedIds)
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 5)
        #expect(gen.nextId() == 6)
        #expect(gen.nextId() == 7)
        #expect(gen.nextId() == 8)
        #expect(gen.nextId() == 9)
        #expect(gen.nextId() == 10)
        #expect(gen.nextId() == 12)

        for i in 13...303 {
            #expect(gen.nextId() == EntityIdentifier(index: UInt32(i), generation: 1))
        }

        // 304 is in use already.
        #expect(gen.nextId() == 305)
        #expect(gen.nextId() == 306)
    }

    @Test func generateWithSingleInitialId() {
        let gen = DefaultEntityIdGenerator(startProviding: [0])
        #expect(gen.nextId() == 0)
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)
    }

    @Test func generateWithInitialIdsNeverRepeatsInUseIds() {
        let gen = DefaultEntityIdGenerator(startProviding: [2, 0])
        let generatedIds = (0..<5).map { _ in gen.nextId() }
        #expect(generatedIds == [0, 2, 1, 3, 4])
    }

    @Test func generatorMarkUnused() {
        let gen = DefaultEntityIdGenerator()
        #expect(gen.nextId() == 0)
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)

        gen.markUnused(entityId: 1)

        // a recycled index is provided again, with the next generation
        #expect(gen.nextId() == EntityIdentifier(index: 1, generation: 2))
        #expect(gen.nextId() == 3)
        #expect(gen.nextId() == 4)

        gen.markUnused(entityId: 3)
        gen.markUnused(entityId: 0)

        #expect(gen.nextId() == EntityIdentifier(index: 0, generation: 2))
        #expect(gen.nextId() == EntityIdentifier(index: 3, generation: 2))

        gen.markUnused(entityId: EntityIdentifier(index: 3, generation: 2))

        #expect(gen.nextId() == EntityIdentifier(index: 3, generation: 3))
        #expect(gen.nextId() == 5)
        #expect(gen.nextId() == 6)
        #expect(gen.nextId() == 7)
        #expect(gen.nextId() == 8)
    }
}
