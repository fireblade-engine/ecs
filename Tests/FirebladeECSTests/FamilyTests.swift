//
//  FamilyTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct FamilyTests {
    private func createDefaultEntity(in nexus: Nexus) {
        let e = nexus.createEntity()
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }

    @Test func familyCreation() {
        let nexus = Nexus()
        let family = nexus.family(requires: Position.self,
                                  excludesAll: Name.self)

        #expect(family.nexus === nexus)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 0)
        #expect(!family.traits.description.isEmpty)
        #expect(!family.traits.debugDescription.isEmpty)

        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [Name.self])
        #expect(family.traits == traits)
    }

    @Test func familyReuse() {
        let nexus = Nexus()
        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)

        let familyB = nexus.family(requires: Position.self,
                                   excludesAll: Name.self)

        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)

        #expect(familyA == familyB)
    }

    @Test func familyAbandoned() {
        let nexus = Nexus()
        #expect(nexus.numFamilies == 0)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 0)
        _ = nexus.family(requires: Position.self)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 0)
        let entity = nexus.createEntity()
        #expect(!entity.has(Position.self))
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 1)
        entity.assign(Position(x: 1, y: 1))
        #expect(entity.has(Position.self))
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numEntities == 1)
        entity.remove(Position.self)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 1)
        nexus.destroy(entity: entity)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 0)
    }

    @Test func familyLateMember() {
        let nexus = Nexus()
        let eEarly = nexus.createEntity(with: Position(x: 1, y: 2))
        #expect(nexus.numFamilies == 0)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numEntities == 1)
        let family = nexus.family(requires: Position.self)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numEntities == 1)
        let eLate = nexus.createEntity(with: Position(x: 1, y: 2))
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 2)
        #expect(nexus.numEntities == 2)
        #expect(family.isMember(eEarly))
        #expect(family.isMember(eLate))
    }

    @Test func familyExchange() {
        let nexus = Nexus()
        let number: Int = 10

        for i in 0..<number {
            nexus.createEntity(with: Position(x: i + 1, y: i + 2))
        }

        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Velocity.self)

        let familyB = nexus.family(requires: Velocity.self,
                                   excludesAll: Position.self)

        #expect(familyA.count == 10)
        #expect(familyB.count == 0)

        familyA
            .entityAndComponents
            .forEach { (entity: Entity, _: Position) in
                entity.assign(Velocity(a: 3.14))
                entity.remove(Position.self)
            }

        #expect(familyA.count == 0)
        #expect(familyB.count == 10)

        familyB
            .entityAndComponents
            .forEach { (entity: Entity, velocity: Velocity) in
                entity.assign(Position(x: 1, y: 2))
                entity.remove(velocity)
            }

        #expect(familyA.count == 10)
        #expect(familyB.count == 0)
    }

    @Test func familyMemberBasicIteration() {
        let nexus = Nexus()
        for i in 0..<1000 {
            nexus.createEntity(with: Position(x: i + 1, y: i + 2))
            nexus.createEntity(with: Velocity(a: Float(i)))
        }

        let familyA = nexus.family(requires: Position.self,
                                   excludesAll: Velocity.self)

        let familyB = nexus.family(requires: Velocity.self,
                                   excludesAll: Position.self)

        familyA.forEach { (pos: Position?) in
            #expect(pos != nil)
        }

        familyB.forEach { (vel: Velocity?) in
            #expect(vel != nil)
        }
    }

    @Test func familyBulkDestroy() {
        let nexus = Nexus()
        let count = 10_000

        for _ in 0..<count {
            createDefaultEntity(in: nexus)
        }

        let family = nexus.family(requires: Position.self)

        #expect(family.memberIds.count == count)

        let currentCount: Int = (count / 2)

        family
            .entities
            .prefix(currentCount)
            .forEach { (entity: Entity) in
                entity.destroy()
            }

        #expect(family.memberIds.count == (count / 2))

        for _ in 0..<count {
            createDefaultEntity(in: nexus)
        }

        #expect(family.memberIds.count == count + (count / 2))
    }

    @Test func familyDestroyMembers() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Position.self, Color.self)

        family.createMember(with: (Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3)))
        family.createMember(with: (Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6)))
        nexus.createEntity(with: Name(name: "anotherEntity"))

        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 5)
        #expect(nexus.numEntities == 3)
        #expect(family.count == 2)

        #expect(family.destroyMembers())

        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numEntities == 1)
        #expect(family.count == 0)

        #expect(!family.destroyMembers())

        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numEntities == 1)
        #expect(family.count == 0)
    }

    @Test func familyCreateMembers() {
        let nexus = Nexus()
        let position = Position(x: 0, y: 1)
        let name = Name(name: "SomeName")
        let velocity = Velocity(a: 123)
        let party = Party(partying: true)
        let color = Color()

        let family1 = nexus.family(requires: Position.self, excludesAll: Name.self)
        #expect(family1.isEmpty)
        family1.createMember(with: position)
        #expect(family1.count == 1)

        let family2 = nexus.family(requiresAll: Position.self, Name.self)
        #expect(family2.isEmpty)
        family2.createMember(with: (position, name))
        #expect(family2.count == 1)

        let family3 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self)
        #expect(family3.isEmpty)
        family3.createMember(with: (position, name, velocity))
        #expect(family3.count == 1)

        let family4 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self, Party.self)
        #expect(family4.isEmpty)
        family4.createMember(with: (position, name, velocity, party))
        #expect(family4.count == 1)

        let family5 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self, Party.self, Color.self)
        #expect(family5.isEmpty)
        family5.createMember(with: (position, name, velocity, party, color))
        #expect(family5.count == 1)
    }
}
