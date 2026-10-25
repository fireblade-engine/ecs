//
//  NexusValueChangeEventTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private final class Health: Component, @unchecked Sendable {
    var points = 10
}

private final class Mana: Component, @unchecked Sendable {
    var points = 5
}

/// Records events and counts reads of its subscription.
private final class Recorder: NexusEventDelegate, @unchecked Sendable {
    private let mask: NexusEventMask?
    private(set) var events: [NexusEvent] = []
    private(set) var subscriptionReads = 0

    /// A `nil` mask uses the protocol default.
    init(mask: NexusEventMask? = nil) {
        self.mask = mask
    }

    var subscribedEvents: NexusEventMask {
        subscriptionReads += 1
        return mask ?? .structural
    }

    func nexusEvent(_ event: NexusEvent) {
        events.append(event)
    }

    func nexusNonFatalError(_: String) {}
}

/// A delegate that does not implement `subscribedEvents`.
private final class DefaultDelegate: NexusEventDelegate, @unchecked Sendable {
    func nexusEvent(_: NexusEvent) {}
    func nexusNonFatalError(_: String) {}
}

@Suite struct NexusValueChangeEventTests {
    @Test func defaultSubscriptionIsStructural() {
        #expect(DefaultDelegate().subscribedEvents == .structural)
        #expect(NexusEventMask.all == [.structural, .valueChanges])
    }

    @Test func structuralMaskDeliversStructuralOnly() {
        let nexus = Nexus()
        let recorder = Recorder(mask: .structural)
        nexus.delegate = recorder
        let entity = nexus.createEntity()
        entity.set(Health())
        #expect(nexus.modify(Health.self, for: entity.identifier) { $0.points = 1 })
        nexus.withComponents(of: Health.self) { _, values in values[0].points = 2 }
        #expect(recorder.events.count == 2)
        #expect(recorder.events[0] is EntityCreated)
        #expect(recorder.events[1] is ComponentAdded)
    }

    @Test func valueChangesMaskDeliversModified() throws {
        let nexus = Nexus()
        let recorder = Recorder(mask: .valueChanges)
        nexus.delegate = recorder
        let entity = nexus.createEntity()
        entity.set(Health())
        #expect(nexus.modify(Health.self, for: entity.identifier) { $0.points = 1 })
        // structural events are delivered whatever the mask says
        #expect(recorder.events.count == 3)
        let modified = try #require(recorder.events[2] as? ComponentModified)
        #expect(modified.entityId == entity.identifier)
        #expect(modified.component == Health.identifier)
        #expect(nexus.backend.get(Health.self, for: entity.identifier)?.points == 1)
    }

    @Test func allMaskDeliversEverything() {
        let nexus = Nexus()
        let recorder = Recorder(mask: .all)
        nexus.delegate = recorder
        let entity = nexus.createEntity()
        entity.set(Health())
        nexus.modify(Health.self, for: entity.identifier) { $0.points = 1 }
        #expect(recorder.events.map { String(describing: type(of: $0)) } == ["EntityCreated", "ComponentAdded", "ComponentModified"])
    }

    @Test func modifyDefaultEmitsAddedThenModified() throws {
        let nexus = Nexus()
        let recorder = Recorder(mask: .all)
        let entity = nexus.createEntity()
        nexus.delegate = recorder
        #expect(nexus.modify(Mana.self, default: Mana(), for: entity.identifier) { $0.points += 1 })
        #expect(recorder.events.count == 2)
        let added = try #require(recorder.events[0] as? ComponentAdded)
        let modified = try #require(recorder.events[1] as? ComponentModified)
        #expect(added.toEntity == entity.identifier)
        #expect(modified.entityId == entity.identifier)
        #expect(nexus.backend.get(Mana.self, for: entity.identifier)?.points == 6)

        // the component exists now: modified only
        #expect(nexus.modify(Mana.self, default: Mana(), for: entity.identifier) { $0.points += 1 })
        #expect(recorder.events.count == 3)
        #expect(recorder.events[2] is ComponentModified)
    }

    @Test func bulkWriteEmitsOneEventPerPass() throws {
        let nexus = Nexus()
        let recorder = Recorder(mask: .valueChanges)
        for _ in 0..<5 {
            nexus.createEntity().set(Health())
        }
        nexus.delegate = recorder
        nexus.withComponents(of: Health.self) { _, values in
            for i in values.indices {
                values[i].points += 1
            }
        }
        #expect(recorder.events.count == 1)
        let event = try #require(recorder.events[0] as? ComponentsModified)
        #expect(event.count == 5)
        #expect(event.component == Health.identifier)

        // nothing to write, nothing to report
        nexus.withComponents(of: Mana.self) { _, _ in }
        #expect(recorder.events.count == 1)
    }

    @Test func eventsCarryGenerationalIdentifiers() throws {
        let nexus = Nexus()
        let recorder = Recorder(mask: .all)
        nexus.delegate = recorder
        let old = nexus.createEntity()
        nexus.destroy(entity: old)
        let reused = nexus.createEntity()
        #expect(reused.identifier.index == old.identifier.index)
        #expect(reused.identifier != old.identifier)
        reused.set(Health())
        nexus.modify(Health.self, for: reused.identifier) { $0.points = 0 }
        let modified = try #require(recorder.events.last as? ComponentModified)
        #expect(modified.entityId == reused.identifier)
        #expect(modified.entityId.generation == reused.identifier.generation)
    }

    @Test func defaultPathNeverCallsTheDelegateOnWrites() {
        let nexus = Nexus()
        let recorder = Recorder()
        nexus.delegate = recorder
        #expect(recorder.subscriptionReads == 1)
        let entity = nexus.createEntity()
        entity.set(Health())
        let before = recorder.events.count
        for _ in 0..<100 {
            nexus.modify(Health.self, for: entity.identifier) { $0.points += 1 }
        }
        nexus.withComponents(of: Health.self) { _, values in values[0].points += 1 }
        #expect(recorder.events.count == before)
        #expect(recorder.subscriptionReads == 1)
        #expect(!nexus.deliversValueChanges)
    }

    @Test func reassigningTheDelegateAppliesANewSubscription() {
        let nexus = Nexus()
        let recorder = Recorder()
        nexus.delegate = recorder
        #expect(!nexus.deliversValueChanges)
        nexus.delegate = nil
        #expect(!nexus.deliversValueChanges)
        let all = Recorder(mask: .all)
        nexus.delegate = all
        #expect(nexus.deliversValueChanges)
    }

    @Test func collisionKeepsReportingWithoutReplacedEvent() {
        let nexus = Nexus()
        let recorder = Recorder(mask: .all)
        let entity = nexus.createEntity()
        entity.set(Health())
        nexus.delegate = recorder
        entity.set(Health())
        #expect(!recorder.events.contains { $0 is ComponentReplaced })
    }
}
