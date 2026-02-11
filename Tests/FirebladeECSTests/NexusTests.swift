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

        #expect(e0.identifier.id == 0)
        #expect(nexus.numEntities == 1)

        let e1 = nexus.createEntity(with: Name(name: "Entity 1"))

        #expect(e1.identifier.id == 1)
        #expect(nexus.numEntities == 2)
        #expect(!nexus.debugDescription.isEmpty)
    }

    @Test func entityDestroy() {
        let nexus = Nexus()
        _ = nexus.createEntity()
        let e1 = nexus.createEntity(with: Name(name: "Entity 1"))
        #expect(nexus.numEntities == 2)

        let e1Fetched = nexus.entity(from: EntityIdentifier(1))
        #expect(nexus.exists(entity: EntityIdentifier(1)))
        #expect(e1Fetched.identifier.id == 1)

        #expect(nexus.destroy(entity: e1))
        #expect(!nexus.destroy(entity: e1))

        #expect(!nexus.exists(entity: EntityIdentifier(1)))

        #expect(nexus.numEntities == 1)

        nexus.clear()

        #expect(nexus.numEntities == 0)
    }

    @Test func componentCreation() {
        let nexus = Nexus()
        #expect(nexus.numEntities == 0)

        let e0: Entity = nexus.createEntity()

        let p0 = Position(x: 1, y: 2)

        e0.assign(p0)
        // component collision: e0.assign(p0)

        #expect(e0.hasComponents)
        #expect(e0.numComponents == 1)

        let rP0: Position? = e0.get(component: Position.self)
        #expect(rP0?.x == 1)
        #expect(rP0?.y == 2)
    }

    @Test func componentDeletion() {
        let nexus = Nexus()
        let identifier: EntityIdentifier = nexus.createEntity().identifier

        let e0 = nexus.entity(from: identifier)

        #expect(e0.numComponents == 0)
        e0.remove(Position.self)
        #expect(e0.numComponents == 0)

        let n0 = Name(name: "myName")
        let p0 = Position(x: 99, y: 111)

        e0.assign(n0)
        #expect(e0.numComponents == 1)
        #expect(e0.hasComponents)

        e0.remove(Name.self)

        #expect(e0.numComponents == 0)
        #expect(!e0.hasComponents)

        e0.assign(p0)

        #expect(e0.numComponents == 1)
        #expect(e0.hasComponents)

        e0.remove(p0)

        #expect(e0.numComponents == 0)
        #expect(!e0.hasComponents)

        e0.assign(n0)
        e0.assign(p0)

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

        #expect(rPos === pos)
        #expect(rName === name)
        #expect(rVel === vel)
    }

    @Test func componentUniqueness() {
        let nexus = Nexus()
        let a = nexus.createEntity()
        let b = nexus.createEntity()
        let c = nexus.createEntity()

        #expect(nexus.numEntities == 3)

        a.assign(Position(x: 0, y: 0))
        b.assign(Position(x: 0, y: 0))
        c.assign(Position(x: 0, y: 0))

        let pA: Position? = a.get()
        let pB: Position? = b.get()

        pA?.x = 23
        pA?.y = 32

        #expect(pB?.x != pA?.x)
        #expect(pB?.y != pA?.y)
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        nexus.createEntities(count: 1000) { ctx in Position(x: ctx.index, y: ctx.index) }

        let entityArray = Array(nexus.makeEntitiesIterator())

        #expect(entityArray.count == 1000)

        #expect(entityArray.contains(where: { $0.identifier.index == 0 }))
        #expect(entityArray.contains(where: { $0.identifier.index == 999 }))
    }
}
