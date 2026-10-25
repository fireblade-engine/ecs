//
//  SingleTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 13.02.19.
//

@testable import FirebladeECS
import Testing

private final class SingleEventRecorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var events: [NexusEvent] = []
    var subscribedEvents: NexusEventMask { .valueChanges }
    func nexusEvent(_ event: NexusEvent) { events.append(event) }
    func nexusNonFatalError(_: String) {}
}

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
        #expect(single.component == singleGame)
    }

    @Test func singleEntityAccess() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        let entity = single.entity
        #expect(entity.nexus === nexus)
        #expect(entity.identifier == single.entityId)
    }

    @Test func singleComponentIsACopy() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        var copy = single.component
        copy.playerHealth = 1
        #expect(single.component.playerHealth != 1)
    }

    @Test func singleSetReplacesComponent() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        var state = single.component
        state.playerHealth = 7
        state.shouldQuit = true
        single.set(state)
        #expect(single.component == state)
        #expect(single.entity[SingleGameState.self] == state)
    }

    @Test func singleModifyWritesInPlace() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        single.modify { $0.playerHealth = 3 }
        #expect(single.component.playerHealth == 3)
    }

    @Test func singleSetAndModifyDeliverEvents() {
        let nexus = Nexus()
        let single = nexus.single(SingleGameState.self)
        let recorder = SingleEventRecorder()
        nexus.delegate = recorder
        single.modify { $0.playerHealth = 3 }
        single.set(SingleGameState(shouldQuit: true, playerHealth: 5))
        #expect(recorder.events.count == 2)
        #expect(recorder.events[0] is ComponentModified)
        #expect(recorder.events[1] is ComponentReplaced)
        withExtendedLifetime(nexus) {}
    }
}
