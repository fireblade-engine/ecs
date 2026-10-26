//
//  ComponentStorageReentrancyTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Foundation
import Testing

/// A component whose `deinit` runs arbitrary code, like user code releasing the last reference would.
private final class Reentrant: Component, @unchecked Sendable {
    nonisolated(unsafe) static var onDeinit: (() -> Void)?

    deinit {
        let hook = Self.onDeinit
        Self.onDeinit = nil
        hook?()
    }
}

private class BaseComponent: Component, @unchecked Sendable {}
private final class SubComponent: BaseComponent, @unchecked Sendable {}

private final class DestroyOnAdd: NexusEventDelegate, @unchecked Sendable {
    var nexus: Nexus?
    var victim: EntityIdentifier?
    var messages: [String] = []

    func nexusEvent(_ event: NexusEvent) {
        if event is ComponentAdded, let victim, let nexus {
            self.victim = nil
            nexus.destroy(entityId: victim)
        }
    }

    func nexusNonFatalError(_ message: String) {
        messages.append(message)
    }
}

@Suite(.serialized) struct ComponentStorageReentrancyTests {
    @Test func deinitReAddingTheSameTypeKeepsMaskAndStorageInSync() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: Reentrant(), Position(x: 1, y: 1))
        Reentrant.onDeinit = { entity.set(Reentrant()) }
        entity.remove(Reentrant.self)

        #expect(entity.has(Reentrant.self))
        #expect(entity.get(Reentrant.self) != nil)
        #expect(entity.numComponents == 2)
        #expect(nexus.numComponents == 2)

        entity.remove(Reentrant.self)
        #expect(!entity.has(Reentrant.self))
        #expect(entity.get(Reentrant.self) == nil)
        #expect(nexus.numComponents == 1)
    }

    @Test func deinitReAddingDuringDestroyLeavesNoTrace() {
        let nexus = Nexus()
        nexus.assertsOnStaleHandles = false
        let family = nexus.family(requires: Reentrant.self)
        let entity = nexus.createEntity(with: Reentrant())
        Reentrant.onDeinit = { entity.set(Reentrant()) }
        nexus.destroy(entity: entity)

        #expect(!nexus.isAlive(entity.identifier))
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
        #expect(family.count == 0)
    }

    @Test func deinitReAddingDuringClearDoesNotCrash() {
        let nexus = Nexus()
        nexus.assertsOnStaleHandles = false
        let entity = nexus.createEntity(with: Reentrant())
        Reentrant.onDeinit = { entity.set(Reentrant()) }
        nexus.clear()
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
    }

    @Test func destroyingMembersDuringFamilyIterationSkipsThem() {
        let nexus = Nexus()
        let entities = (0 ..< 10).map { nexus.createEntity(with: Position(x: $0, y: $0)) }
        let family = nexus.family(requires: Position.self)
        var visited = 0
        for _ in family {
            visited += 1
            for entity in entities {
                nexus.destroy(entity: entity)
            }
        }
        #expect(visited == 1)
        #expect(family.count == 0)
    }

    @Test func clearingTheNexusDuringFamilyIterationSkipsMembers() {
        let nexus = Nexus()
        for index in 0 ..< 10 {
            nexus.createEntity(with: Position(x: index, y: index))
        }
        let family = nexus.family(requires: Position.self)
        var visited = 0
        for (entity, _) in family.entityAndComponents {
            visited += 1
            #expect(nexus.isAlive(entity.identifier))
            nexus.clear()
        }
        #expect(visited == 1)
    }

    @Test func slotReuseDuringIterationNeverYieldsAnotherEntitysComponent() {
        let nexus = Nexus()
        let first = nexus.createEntity(with: Position(x: 1, y: 1))
        let second = nexus.createEntity(with: Position(x: 2, y: 2))
        let family = nexus.family(requires: Position.self)
        var seen: [Int] = []
        for position in family {
            seen.append(position.x)
            nexus.destroy(entity: second)
            // reuses the slot of `second` with a higher generation; it is not a member of the iterated snapshot
            nexus.createEntity(with: Position(x: 3, y: 3))
        }
        #expect(seen == [1])
        #expect(first.get(Position.self)?.x == 1)
    }

    @Test func delegateDestroyingTheEntityDuringAssignDoesNotTrap() {
        let nexus = Nexus()
        nexus.assertsOnStaleHandles = false
        let delegate = DestroyOnAdd()
        delegate.nexus = nexus
        nexus.delegate = delegate
        let entity = nexus.createEntity()
        delegate.victim = entity.identifier
        let components: [Component] = [Position(x: 1, y: 1), Name(name: "n")]
        let assigned = nexus.assign(components: components, to: entity.identifier)

        #expect(!assigned)
        #expect(!nexus.isAlive(entity.identifier))
        #expect(nexus.numComponents == 0)
        #expect(!delegate.messages.isEmpty)
        nexus.delegate = nil
    }

    @Test func subclassInstancesAreStoredUnderTheirDynamicType() {
        // As in 1.x, `Component.identifier` of the instance, and with it the storage, is that of the dynamic type.
        let nexus = Nexus()
        let base: BaseComponent = SubComponent()
        let entity = nexus.createEntity()
        entity.set(base)
        #expect(entity.has(SubComponent.self))
        #expect(entity.get(SubComponent.self) === base)
        #expect(nexus.get(components: entity.identifier) == [SubComponent.identifier])
    }

    @Test func familyOrderIsDeterministicAfterSwapRemoveChurn() {
        func run() -> [Int] {
            let nexus = Nexus()
            let entities = (0 ..< 64).map { nexus.createEntity(with: Position(x: $0, y: 0)) }
            let family = nexus.family(requires: Position.self)
            for index in stride(from: 0, to: 64, by: 3) {
                entities[index].remove(Position.self)
            }
            for index in stride(from: 0, to: 64, by: 6) {
                entities[index].set(Position(x: index, y: 1))
            }
            return family.map(\.x)
        }
        let first = run()
        #expect(first == run())
        #expect(Set(first) == Set((0 ..< 64).filter { $0 % 3 != 0 || $0 % 6 == 0 }))

        // a family created after the churn lists its members in entity order
        let nexus = Nexus()
        let entities = (0 ..< 64).map { nexus.createEntity(with: Position(x: $0, y: 0)) }
        for index in stride(from: 0, to: 64, by: 3) {
            entities[index].remove(Position.self)
        }
        let late = nexus.family(requires: Position.self)
        #expect(late.map(\.x) == (0 ..< 64).filter { $0 % 3 != 0 })
    }

    @Test func snapshotsWithAbsurdEntityIndicesAreRejected() throws {
        let nexus = Nexus()
        try nexus.register([SerialPosition.self])
        let json = #"{"formatVersion":3,"entities":[{"id":4294967295,"components":{"Position":{"x":1,"y":2}}}]}"#
        var decoder = JSONDecoder()
        #expect(throws: ComponentSerializationError.self) {
            try nexus.restoreSnapshot(from: Data(json.utf8), using: &decoder)
        }
        #expect(nexus.numEntities == 0)
    }
}
