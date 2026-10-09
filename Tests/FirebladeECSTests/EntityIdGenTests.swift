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
            #expect(gen.nextId() == EntityIdentifier(EntityIdentifier.Identifier(i)))
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

        for i in 13...304 {
            #expect(gen.nextId() == EntityIdentifier(EntityIdentifier.Identifier(i)))
        }

        #expect(gen.nextId() == 305)
    }

    @Test func generatorMarkUnused() {
        let gen = DefaultEntityIdGenerator()
        #expect(gen.nextId() == 0)
        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 2)

        gen.markUnused(entityId: EntityIdentifier(1))

        #expect(gen.nextId() == 1)
        #expect(gen.nextId() == 3)
        #expect(gen.nextId() == 4)

        gen.markUnused(entityId: 3)
        gen.markUnused(entityId: 0)

        #expect(gen.nextId() == 0)
        #expect(gen.nextId() == 3)

        gen.markUnused(entityId: 3)

        #expect(gen.nextId() == 3)
        #expect(gen.nextId() == 5)
        #expect(gen.nextId() == 6)
        #expect(gen.nextId() == 7)
        #expect(gen.nextId() == 8)
    }
}
