//
//  NexusTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct NexusTests {
    @Test func entityCreate() {
        let nexus = Nexus()
        #expect(nexus.numEntities == 0)

        let e0 = nexus.createEntity()

        #expect(e0.identifier.index == 1) // index 0 is reserved
        #expect(e0.identifier.generation == 0)
        #expect(nexus.numEntities == 1)

        let e1 = nexus.createEntity(with: Name(name: "Entity 1"))

        #expect(e1.identifier.index == 2)
        #expect(nexus.numEntities == 2)
        #expect(!nexus.debugDescription.isEmpty)
    }

    @Test func entityDestroy() throws {
        let nexus = Nexus()
        _ = nexus.createEntity()
        let e1 = nexus.createEntity(with: Name(name: "Entity 1"))
        #expect(nexus.numEntities == 2)

        let e1Fetched = try #require(nexus.entity(e1.identifier))
        #expect(nexus.isAlive(e1.identifier))
        #expect(e1Fetched.identifier.index == 2)

        #expect(nexus.destroy(entity: e1))
        #expect(!nexus.destroy(entity: e1))

        #expect(!nexus.isAlive(e1.identifier))
        #expect(nexus.entity(e1.identifier) == nil)

        #expect(nexus.numEntities == 1)

        nexus.clear()

        #expect(nexus.numEntities == 0)
    }

    @Test func componentCreation() {
        let nexus = Nexus()
        #expect(nexus.numEntities == 0)

        let e0: Entity = nexus.createEntity()

        let p0 = Position(x: 1, y: 2)

        e0.set(p0)
        // component collision: e0.set(p0)

        #expect(e0.hasComponents)
        #expect(e0.numComponents == 1)

        let rP0: Position? = e0.get(Position.self)
        #expect(rP0?.x == 1)
        #expect(rP0?.y == 2)
    }

    @Test func componentDeletion() throws {
        let nexus = Nexus()
        let identifier: EntityIdentifier = nexus.createEntity().identifier

        let e0 = try #require(nexus.entity(identifier))

        #expect(e0.numComponents == 0)
        e0.remove(Position.self)
        #expect(e0.numComponents == 0)

        let n0 = Name(name: "myName")
        let p0 = Position(x: 99, y: 111)

        e0.set(n0)
        #expect(e0.numComponents == 1)
        #expect(e0.hasComponents)

        e0.remove(Name.self)

        #expect(e0.numComponents == 0)
        #expect(!e0.hasComponents)

        e0.set(p0)

        #expect(e0.numComponents == 1)
        #expect(e0.hasComponents)

        e0.remove(p0)

        #expect(e0.numComponents == 0)
        #expect(!e0.hasComponents)

        e0.set(n0)
        e0.set(p0)

        #expect(e0.numComponents == 2)
        let (name, position) = e0.get(components: Name.self, Position.self)

        #expect(name?.name == "myName")
        #expect(position?.x == 99)
        #expect(position?.y == 111)

        e0.destroy()

        #expect(e0.numComponents == 0)
    }

    @Test func componentRetrieval() {
        let nexus = Nexus()
        let pos = Position(x: 1, y: 2)
        let name = Name(name: "myName")
        let vel = Velocity(a: 3)
        let entity = nexus.createEntity(with: pos, name, vel)

        let (rPos, rName, rVel) = entity.get(components: Position.self, Name.self, Velocity.self)

        #expect(rPos == pos)
        #expect(rName == name)
        #expect(rVel == vel)
    }

    @Test func componentUniqueness() {
        let nexus = Nexus()
        let a = nexus.createEntity()
        let b = nexus.createEntity()
        let c = nexus.createEntity()

        #expect(nexus.numEntities == 3)

        a.set(Position(x: 0, y: 0))
        b.set(Position(x: 0, y: 0))
        c.set(Position(x: 0, y: 0))

        // reading returns a copy: changing it changes neither the stored component nor the component of another entity
        var copy: Position? = a.get()
        copy?.x = 23
        #expect(a.get(Position.self) == Position(x: 0, y: 0))

        a.modify(Position.self) {
            $0.x = 23
            $0.y = 32
        }

        #expect(a.get(Position.self) == Position(x: 23, y: 32))
        #expect(b.get(Position.self) == Position(x: 0, y: 0))
        #expect(c.get(Position.self) == Position(x: 0, y: 0))
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        nexus.createEntities(count: 1000) { ctx in Position(x: ctx.index, y: ctx.index) }

        let entityArray = Array(nexus.makeEntitiesIterator())

        #expect(entityArray.count == 1000)

        #expect(entityArray.contains(where: { $0.identifier.index == 1 }))
        #expect(entityArray.contains(where: { $0.identifier.index == 1000 }))
    }
}
