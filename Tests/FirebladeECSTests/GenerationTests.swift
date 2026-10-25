//
//  GenerationTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

/// Records the non-fatal errors of a nexus.
private final class ErrorRecorder: NexusEventDelegate, @unchecked Sendable {
    var messages: [String] = []

    func nexusEvent(_: NexusEvent) {}

    func nexusNonFatalError(_ message: String) {
        messages.append(message)
    }
}

@Suite struct GenerationTests {
    /// A nexus whose first entity was destroyed and whose slot was reused: `stale` is `1v0`, `reused` is `1v1`.
    private func makeReusedSlot() -> (nexus: Nexus, stale: Entity, reused: Entity) {
        let nexus = Nexus()
        nexus.assertsOnStaleHandles = false
        let stale = nexus.createEntity(with: Position(x: 1, y: 1))
        nexus.destroy(entity: stale)
        let reused = nexus.createEntity(with: Name(name: "reused"))
        return (nexus, stale, reused)
    }

    @Test func destroyBumpsGenerationOfReusedSlot() {
        let (nexus, stale, reused) = makeReusedSlot()
        #expect(nexus.numEntities == 1)
        #expect(stale.identifier == EntityIdentifier(index: 1, generation: 0))
        #expect(reused.identifier == EntityIdentifier(index: 1, generation: 1))
        #expect(stale.identifier != reused.identifier)
        #expect(stale != reused)
    }

    @Test func staleIdentifierIsNotAlive() throws {
        let (nexus, stale, reused) = makeReusedSlot()
        #expect(!nexus.isAlive(stale.identifier))
        #expect(nexus.isAlive(reused.identifier))
        #expect(nexus.entity(stale.identifier) == nil)
        #expect(try #require(nexus.entity(reused.identifier)) == reused)
    }

    @Test func invalidAndUnknownIdentifiersAreNotAlive() {
        let nexus = Nexus()
        nexus.createEntity()
        #expect(!nexus.isAlive(.invalid))
        #expect(nexus.entity(.invalid) == nil)
        #expect(!nexus.isAlive(EntityIdentifier(index: 99, generation: 0)))
        #expect(!nexus.isAlive(EntityIdentifier(index: 1, generation: 1)))
    }

    @Test func staleHandleNeverSeesTheNewEntity() {
        let (nexus, stale, reused) = makeReusedSlot()
        #expect(!stale.has(Position.self))
        #expect(stale.get(Position.self) == nil)
        #expect(stale.numComponents == 0)
        #expect(!stale.has(Name.self))
        #expect(reused.has(Name.self))
        let family = nexus.family(requires: Name.self)
        #expect(family.count == 1)
        #expect(!nexus.isMember(stale, in: FamilyTraitSet(requiresAll: [Name.self], excludesAll: [])))
        #expect(nexus.isMember(reused, in: FamilyTraitSet(requiresAll: [Name.self], excludesAll: [])))
    }

    @Test func mutatingStaleHandleReturnsFalseAndKeepsTheNewEntity() {
        let (nexus, stale, reused) = makeReusedSlot()

        #expect(!nexus.assign(component: Position(x: 2, y: 2), entityId: stale.identifier))
        #expect(!nexus.assign(components: [Position(x: 2, y: 2)], to: stale.identifier))
        #expect(!nexus.remove(component: Name.identifier, from: stale.identifier))
        #expect(!nexus.removeAll(components: stale.identifier))
        #expect(!nexus.destroy(entity: stale))
        #expect(!stale.set(value: 3, for: \Position.x))
        stale.set(Position(x: 4, y: 4))
        stale.remove(Name.self)
        stale.removeAll()
        stale.destroy()

        #expect(nexus.isAlive(reused.identifier))
        #expect(reused.has(Name.self))
        #expect(!reused.has(Position.self))
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 1)
    }

    @Test func mutatingDestroyedEntityWithoutReuseReturnsFalse() {
        let nexus = Nexus()
        nexus.assertsOnStaleHandles = false
        let entity = nexus.createEntity()
        nexus.destroy(entity: entity)
        #expect(!nexus.assign(component: Position(x: 0, y: 0), entityId: entity.identifier))
        #expect(!nexus.remove(component: Position.identifier, from: entity.identifier))
        #expect(nexus.numComponents == 0)
        #expect(nexus.numEntities == 0)
    }

    @Test func staleMutationNamesBothVersions() {
        let (nexus, stale, _) = makeReusedSlot()
        let recorder = ErrorRecorder()
        nexus.delegate = recorder
        stale.set(Position(x: 1, y: 1))
        #expect(recorder.messages == ["stale handle 1v0, slot is at 1v1"])

        let destroyed = nexus.createEntity()
        nexus.destroy(entity: destroyed)
        destroyed.removeAll()
        #expect(recorder.messages.last == "stale handle 2v0, slot is free")
    }

    @Test func slotIsReusedWithIncreasingGenerations() {
        let nexus = Nexus()
        var identifier = nexus.createEntity().identifier
        var seen: Set<EntityIdentifier> = [identifier]
        for generation in 1 ..< 100 {
            nexus.destroy(entityId: identifier)
            identifier = nexus.createEntity().identifier
            #expect(identifier.index == 1)
            #expect(identifier.generation == UInt32(generation))
            #expect(seen.insert(identifier).inserted)
        }
    }

    @Test func slotIsRetiredAtMaxGeneration() {
        let nexus = Nexus()
        // injection: the first entity starts three generations below the limit
        let start = EntityIdentifier(index: 1, generation: .max - 3)
        nexus.entityIdGenerator = DefaultEntityIdGenerator(startProviding: [start])

        var entity = nexus.createEntity()
        #expect(entity.identifier == start)
        for expectedGeneration: UInt32 in [.max - 2, .max - 1] {
            nexus.destroy(entity: entity)
            entity = nexus.createEntity()
            #expect(entity.identifier == EntityIdentifier(index: 1, generation: expectedGeneration))
        }

        // destroying generation max - 1 would reach UInt32.max: the slot is retired instead of wrapping around
        let last = entity.identifier
        nexus.destroy(entity: entity)
        let next = nexus.createEntity()
        #expect(next.identifier == EntityIdentifier(index: 2, generation: 0))
        #expect(!nexus.isAlive(last))
        for _ in 0 ..< 10 {
            let created = nexus.createEntity()
            #expect(created.identifier.index != 1)
        }
    }

    @Test func generatorNeverWrapsGenerationAround() {
        let gen = DefaultEntityIdGenerator()
        let id = EntityIdentifier(index: 5, generation: .max)
        gen.markUnused(entityId: id)
        gen.markUnused(entityId: EntityIdentifier(index: 6, generation: .max - 1))
        #expect(gen.nextId() == EntityIdentifier(index: 1, generation: 0))
    }

    @Test func eventsCarryTheFullIdentifier() {
        let nexus = Nexus()
        let recorder = EventRecorder()
        nexus.delegate = recorder
        let first = nexus.createEntity()
        nexus.destroy(entity: first)
        let second = nexus.createEntity()
        #expect(recorder.created == [first.identifier, second.identifier])
        #expect(recorder.destroyed == [first.identifier])
        #expect(second.identifier.generation == 1)
    }
}

private final class EventRecorder: NexusEventDelegate, @unchecked Sendable {
    var created: [EntityIdentifier] = []
    var destroyed: [EntityIdentifier] = []

    func nexusEvent(_ event: NexusEvent) {
        if let event = event as? EntityCreated {
            created.append(event.entityId)
        } else if let event = event as? EntityDestroyed {
            destroyed.append(event.entityId)
        }
    }

    func nexusNonFatalError(_: String) {}
}
