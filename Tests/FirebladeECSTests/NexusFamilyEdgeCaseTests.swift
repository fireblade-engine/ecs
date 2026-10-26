//
//  NexusFamilyEdgeCaseTests.swift
//  FirebladeECSTests
//
//  Created by Conductor on 11.02.26.
//

import Testing
@testable import FirebladeECS

@Suite struct NexusFamilyEdgeCaseTests {
    @Test(arguments: Nexus.StorageKind.allCases) func canBecomeMemberUnknownEntity(_ storage: Nexus.StorageKind) {
        let nexus1 = Nexus(storage: storage)
        let nexus2 = Nexus(storage: storage)

        // Create entity in nexus1
        let entity1 = nexus1.createEntity()

        // Check if entity1 can become member in nexus2
        // It should return false because nexus2 doesn't know about entity1
        let family2 = nexus2.family(requiresAll: Position.self)

        #expect(nexus2.canBecomeMember(entity1, in: family2.traits) == false)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func membersWithUnknownTraits(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let traits = FamilyTraitSet(requiresAll: [Position.self], excludesAll: [])
        // We didn't create a family with these traits.

        let members = nexus.members(withFamilyTraits: traits)
        #expect(members.isEmpty)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func settingExistingComponentReplaces(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)
        entity.set(pos)
        // Set another component of the same type -> it replaces the first one
        let replacement = Position(x: 3, y: 4)
        entity.set(replacement)
        #expect(entity.get(Position.self) == replacement)
        #expect(entity.numComponents == 1)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func settingExistingComponentsReplacesMultiple(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)
        let name = Name(name: "Test")
        let components: [Component] = [pos, name]
        entity.set(components)
        // Set other components of the same types again -> they replace the first ones
        let newPos = Position(x: 3, y: 4)
        let newName = Name(name: "Other")
        entity.set([newPos, newName] as [Component])
        #expect(entity.get(Position.self) == newPos)
        #expect(entity.get(Name.self) == newName)
        #expect(entity.numComponents == 2)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func assignGenericComponent(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        let pos = Position(x: 1, y: 2)

        func assignGeneric<C: Component>(_ c: C) {
            entity.set(c)
        }

        assignGeneric(pos)
        #expect(entity.has(Position.self))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func removeAllFromDestroyedEntity(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        nexus.assertsOnStaleHandles = false
        let entity = nexus.createEntity()
        entity.destroy()

        // This should trigger the guard else in removeAll
        let result = nexus.removeAll(components: entity.identifier)
        #expect(result == false)
    }
}
