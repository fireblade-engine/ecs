//
//  SingleTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 13.02.19.
//

@testable import FirebladeECS
import Testing

@Suite struct SingleTests {
    @Test func singleCreation() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        #expect(single.nexus === nexus)
        #expect(single.traits.requiresAll.count == 1)
        #expect(single.traits.excludesAll.count == 0)

        #expect(nexus.familyMembersByTraits.keys.count == 1)
        #expect(nexus.familyMembersByTraits.values.count == 1)

        let traits = FamilyTraitSet(requiresAll: [SingleGameState.self], excludesAll: [])
        #expect(single.traits == traits)
    }

    @Test func singleReuse() {
        let nexus = Nexus()
        let singleA = nexus.single(SingleGameState.self)

        let singleB = nexus.single(SingleGameState.self)

        #expect(nexus.familyMembersByTraits.keys.count == 1)
        #expect(nexus.familyMembersByTraits.values.count == 1)

        #expect(singleA == singleB)
    }

    @Test func singleEntityAndComponentCreation() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        let gameState = SingleGameState()
        #expect(single.component.shouldQuit == gameState.shouldQuit)
        #expect(single.component.playerHealth == gameState.playerHealth)
    }

    @Test func singleCreationOnExistingFamilyMember() {
        let nexus = Nexus()
        _ = nexus.createEntity(with: Position(x: 1, y: 2))
        let singleGame = SingleGameState()
        _ = nexus.createEntity(with: singleGame)
        let single = nexus.single(SingleGameState.self)
        #expect(singleGame === single.component)
    }

    @Test func singleEntityAccess() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        let entity = single.entity
        #expect(entity.nexus === nexus)
        #expect(entity.identifier == single.entityId)
    }
}
