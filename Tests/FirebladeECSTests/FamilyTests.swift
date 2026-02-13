//
//  FamilyTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct FamilyTests {

    @Test func familyCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Position.self,
                                  excludesAll: Name.self)

        #expect(family.nexus === nexus)
        #expect(family.traits.requiresAll.count == 1)
        #expect(family.traits.excludesAll.count == 1)
    }

    @Test func familyReuse() {
        let nexus = Nexus()
        let familyA = nexus.family(requiresAll: Position.self,
                                   excludesAll: Name.self)

        let familyB = nexus.family(requiresAll: Position.self,
                                   excludesAll: Name.self)

        #expect(familyA == familyB)
    }

    @Test func traitsMatching() {
        let nexus = Nexus()
        _ = nexus.createEntity(with: Position(x: 1, y: 2))
        _ = nexus.createEntity(with: Position(x: 3, y: 4), Name(name: "MyName"))
        _ = nexus.createEntity(with: Name(name: "YourName"))

        #expect(nexus.numComponents == 4)
        #expect(nexus.numEntities == 3)
        _ = nexus.family(requiresAll: Position.self)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numComponents == 4)

        let family = nexus.family(requiresAll: Position.self,
                                  excludesAll: Name.self)

        #expect(family.count == 1)
        #expect(nexus.numFamilies == 2)
    }

    @Test func iteration() {
        let nexus = Nexus()
        let count = 1000
        for i in 0..<count {
            let entity = nexus.createEntity()
            entity.assign(Position(x: i, y: i))
        }

        #expect(nexus.numComponents == count)
        #expect(nexus.numEntities == count)
        let family = nexus.family(requiresAll: Position.self)

        #expect(family.memberIds.count == count)

        family.forEach { (pos: Position) in
            #expect(pos.x == pos.y)
        }
    }

    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Position.self, Color.self)

        family.createMember(with: Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3))
        family.createMember(with: Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6))
        nexus.createEntity(with: Name(name: "anotherEntity"))

        #expect(family.count == 2)
    }

    @Test func memberCreation1() {
        let nexus = Nexus()
        let position = Position(x: 1, y: 2)
        let color = Color()

        let family1 = nexus.family(requiresAll: Position.self, excludesAll: Name.self)
        #expect(family1.isEmpty)
        family1.createMember(with: position)
        #expect(family1.count == 1)

        let name = Name(name: "some")
        let family2 = nexus.family(requiresAll: Position.self, Name.self)
        #expect(family2.isEmpty)
        family2.createMember(with: position, name)
        #expect(family2.count == 1)

        let velocity = Velocity(a: 3.14)
        let family3 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self)
        #expect(family3.isEmpty)
        family3.createMember(with: position, name, velocity)
        #expect(family3.count == 1)

        let party = Party(partying: true)
        let family4 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self, Party.self)
        #expect(family4.isEmpty)
        family4.createMember(with: position, name, velocity, party)
        #expect(family4.count == 1)

        let family5 = nexus.family(requiresAll: Position.self, Name.self, Velocity.self, Party.self, Color.self)
        #expect(family5.isEmpty)
        family5.createMember(with: position, name, velocity, party, color)
        #expect(family5.count == 1)
    }
}
