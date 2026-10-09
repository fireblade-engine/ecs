//
//  EntityCreationTests.swift
//
//
//  Created by Christian Treffs on 30.07.20.
//

import FirebladeECS
import Testing

@Suite struct EntityCreationTests {
    @Test func createEntityOneComponent() throws {
        let nexus = Nexus()
        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
        }

        #expect(entity[\Position.x] == 1)
        #expect(entity[\Position.y] == 2)

        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numFamilies == 0)
    }

    @Test func createEntityMultipleComponents() throws {
        let nexus = Nexus()

        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
            Name(name: "Hello")
        }

        #expect(entity[\Position.x] == 1)
        #expect(entity[\Position.y] == 2)

        #expect(entity[\Name.name] == "Hello")

        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 2)
        #expect(nexus.numFamilies == 0)
    }

    @Test func bulkCreateEntitiesOneComponent() throws {
        let nexus = Nexus()

        let entities = nexus.createEntities(count: 100) { ctx in
            Velocity(a: Float(ctx.index))
        }

        #expect(entities[0][\Velocity.a] == 0)
        #expect(entities[99][\Velocity.a] == 99)

        #expect(nexus.numEntities == 100)
        #expect(nexus.numComponents == 100)
        #expect(nexus.numFamilies == 0)
    }

    @Test func bulkCreateEntitiesMultipleComponents() throws {
        let nexus = Nexus()

        let entities = nexus.createEntities(count: 100) { ctx in
            Position(x: ctx.index, y: ctx.index)
            Name(name: "\(ctx.index)")
        }

        #expect(entities[0][\Position.x] == 0)
        #expect(entities[0][\Position.y] == 0)
        #expect(entities[0][\Name.name] == "0")
        #expect(entities[99][\Position.x] == 99)
        #expect(entities[99][\Position.y] == 99)
        #expect(entities[99][\Name.name] == "99")

        #expect(nexus.numEntities == 100)
        #expect(nexus.numComponents == 200)
        #expect(nexus.numFamilies == 0)
    }
}
