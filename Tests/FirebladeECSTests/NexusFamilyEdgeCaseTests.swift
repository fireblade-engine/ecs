//
//  NexusFamilyEdgeCaseTests.swift
//  FirebladeECSTests
//
//  Created by Conductor on 11.02.26.
//

import Testing
@testable import FirebladeECS

@Suite struct NexusFamilyEdgeCaseTests {
    @Test func canBecomeMemberUnknownEntity() {
        let nexus1 = Nexus()
        let nexus2 = Nexus()

        // Create entity in nexus1
        let entity1 = nexus1.createEntity()

        // Check if entity1 can become member in nexus2
        // It should return false because nexus2 doesn't know about entity1
        let family2 = nexus2.family(requires: Position.self)

        #expect(nexus2.canBecomeMember(entity1, in: family2.traits) == false)
    }

    @Test func membersWithUnknownTraits() {
        let nexus = Nexus()
        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [])
        // We didn't create a family with these traits.

        let members = nexus.members(withFamilyTraits: traits)
        #expect(members.isEmpty)
    }

    @Test func componentCollision() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)
        nexus.assign(component: pos, to: entity)
        // Assign same component again -> collision
        let success = nexus.assign(component: pos, to: entity)
        #expect(success == false)
    }

    @Test func componentCollisionMultiple() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Test")
        let components: [Component] = [pos, name]
        nexus.assign(components: components, to: entity)
        // Assign same components again -> collision
        let success = nexus.assign(components: components, to: entity)
        #expect(success == false)
    }

    @Test func assignGenericComponent() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)

        func assignGeneric<C: Component>(_ c: C) {
            nexus.assign(component: c, to: entity)
        }

        assignGeneric(pos)
        #expect(entity.has(Position.self))
    }

    @Test func removeAllFromDestroyedEntity() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        entity.destroy()

        // This should trigger the guard else in removeAll
        let result = nexus.removeAll(components: entity.identifier)
        #expect(result == false)
    }
}
