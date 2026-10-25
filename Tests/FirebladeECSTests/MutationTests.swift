//
//  MutationTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Health: Equatable, Component, DefaultInitializable, Sendable {
    var hp = 100
    var armor: Int?
    init() {}
    init(hp: Int) { self.hp = hp }
}

private struct Counter: Component, DefaultInitializable, Sendable {
    var value = 0
    init() {}
}

private struct Speed: Component, Sendable {
    var dx = 0
    var dy = 0
    init(dx: Int, dy: Int) {
        self.dx = dx
        self.dy = dy
    }
}

private struct Boom: Error {}

/// Passing a subscript as `inout` is what starts an in place access of the component. Changing a property of a class
/// component through `entity[Health.self]?.hp = 1` only reads the reference, so it takes no write access.
private func bump(_ counter: inout Counter?) {
    counter?.value += 1
}

private func bump(_ counter: inout Counter) {
    counter.value += 1
}

private func lower(_ health: inout Health?) {
    health?.hp -= 1
}

// An entity does not keep its nexus alive, so every test holds the nexus until it ends.

/// Takes `inout` so the tests can use `var` copies, which a class component would make a compile warning.
private func hurt(_ health: inout Health) {
    health.hp -= 10
}

private final class Recorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var events: [NexusEvent] = []
    var subscribedEvents: NexusEventMask { .all }
    func nexusEvent(_ event: NexusEvent) { events.append(event) }
    func nexusNonFatalError(_: String) {}

    /// Short names of the component events, in order.
    var names: [String] {
        events.compactMap {
            switch $0 {
            case is ComponentAdded: "added"
            case is ComponentReplaced: "replaced"
            case is ComponentModified: "modified"
            case is ComponentRemoved: "removed"
            default: nil
            }
        }
    }
}

private func makeNexus() -> Nexus {
    let nexus = Nexus()
    nexus.assertsOnStaleHandles = false
    return nexus
}

@Suite struct MutationTests {
    // MARK: modify

    @Test func modifyChangesInPlaceAndLosesNoWrites() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Counter())
        for _ in 0..<1000 {
            #expect(entity.modify(Counter.self) { $0.value += 1 })
            entity[Counter.self]?.value += 1
            entity.modify(Counter.self, default: Counter()) { $0.value += 1 }
        }
        #expect(entity.get(Counter.self)?.value == 3000)
    }

    @Test func modifyOfMissingComponentReturnsFalseAndSkipsBody() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        var called = false
        #expect(!entity.modify(Health.self) { _ in called = true })
        #expect(!called)
        #expect(!entity.has(Health.self))
    }

    @Test func modifyDefaultEvaluatesDefaultOnlyWhenMissing() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        var made = 0
        func makeHealth() -> Health {
            made += 1
            return Health(hp: 7)
        }
        entity.modify(Health.self, default: makeHealth()) { $0.hp += 1 }
        #expect(made == 1)
        #expect(entity.get(Health.self)?.hp == 8)
        entity.modify(Health.self, default: makeHealth()) { $0.hp += 1 }
        #expect(made == 1)
        #expect(entity.get(Health.self)?.hp == 9)
    }

    @Test func modifyOfDestroyedEntityIsANoOp() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let stale = nexus.createEntity(with: Health())
        stale.destroy()
        let reused = nexus.createEntity()
        var called = false
        #expect(!stale.modify(Health.self) { _ in called = true })
        stale.modify(Counter.self, default: Counter()) { _ in called = true }
        #expect(!called)
        #expect(!reused.has(Counter.self))
        #expect(!reused.has(Health.self))
        #expect(!stale.set(Counter()).has(Counter.self) || stale.identifier != reused.identifier)
        #expect(nexus.numComponents == 0)
    }

    @Test func modifyRethrowsAndStillReportsTheChange() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        let entity = nexus.createEntity(with: Health())
        nexus.delegate = recorder
        #expect(throws: Boom.self) {
            try entity.modify(Health.self) {
                $0.hp = 1
                throw Boom()
            }
        }
        #expect(entity.get(Health.self)?.hp == 1)
        #expect(recorder.names == ["modified"])
        // the write access ended: the component can be accessed again
        #expect(entity.modify(Health.self) { $0.hp = 2 })
    }

    // MARK: subscripts

    @Test func optionalSubscriptReadsACopyAndNeverInserts() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        #expect(entity[Health.self] == nil)
        #expect(!entity.has(Health.self))
        entity[Health.self]?.hp = 5
        #expect(!entity.has(Health.self))
        #expect(entity.numComponents == 0)
    }

    @Test func optionalSubscriptMutatesInPlace() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity[Health.self]?.hp -= 10
        #expect(entity[Health.self]?.hp == 90)
        lower(&entity[Health.self])
        #expect(entity[Health.self]?.hp == 89)
        entity[Health.self] = Health(hp: 1)
        #expect(entity[Health.self]?.hp == 1)
        entity[Health.self] = nil
        #expect(!entity.has(Health.self))
    }

    @Test func optionalSubscriptAssigningNilThroughInoutRemoves() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        let entity = nexus.createEntity(with: Health(), Counter())
        let family = nexus.family(requires: Health.self)
        #expect(family.count == 1)
        nexus.delegate = recorder
        func clear(_ value: inout Health?) { value = nil }
        clear(&entity[Health.self])
        #expect(!entity.has(Health.self))
        #expect(entity.has(Counter.self))
        #expect(entity.numComponents == 1)
        #expect(family.count == 0)
        #expect(recorder.names.contains("removed"))
        // storage stays consistent
        entity.set(Health(hp: 3))
        #expect(entity.get(Health.self)?.hp == 3)
        #expect(entity.get(Counter.self)?.value == 0)
    }

    @Test func optionalSubscriptAssigningAValueThroughInoutToAMissingComponentAdds() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        func fill(_ value: inout Health?) { value = Health(hp: 4) }
        fill(&entity[Health.self])
        #expect(entity.get(Health.self)?.hp == 4)
    }

    @Test func defaultSubscriptReadsWithoutInserting() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        #expect(entity[Counter.self, default: Counter()].value == 0)
        #expect(!entity.has(Counter.self))
    }

    @Test func defaultSubscriptInsertsWhenMutating() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        bump(&entity[Counter.self, default: Counter()])
        #expect(entity.get(Counter.self)?.value == 1)
        bump(&entity[Counter.self, default: Counter()])
        #expect(entity.get(Counter.self)?.value == 2)
    }

    @Test func defaultSubscriptEvaluatesDefaultOnlyWhenNeeded() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Counter())
        var made = 0
        func makeCounter() -> Counter {
            made += 1
            return Counter()
        }
        bump(&entity[Counter.self, default: makeCounter()])
        _ = entity[Counter.self, default: makeCounter()]
        #expect(made == 0)
    }

    @Test func defaultSubscriptOfDestroyedEntityDoesNotInsert() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let stale = nexus.createEntity()
        stale.destroy()
        let reused = nexus.createEntity()
        bump(&stale[Counter.self, default: Counter()])
        #expect(!reused.has(Counter.self))
        #expect(nexus.numComponents == 0)
    }

    // MARK: key paths

    @Test func writableKeyPathChangesTheStoredComponent() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity[\Health.hp] = 3
        #expect(entity.get(Health.self)?.hp == 3)
        #expect(entity[\Health.hp] == 3)
        entity[\Health.armor] = 9
        #expect(entity[\Health.armor] == 9)
        entity[\Health.armor] = nil
        #expect(entity[\Health.armor] == nil)
    }

    @Test func writableKeyPathAddsADefaultComponent() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        nexus.delegate = recorder
        let entity = nexus.createEntity()
        entity[\Health.hp] = 3
        #expect(entity.get(Health.self)?.hp == 3)
        #expect(recorder.names == ["added", "modified"])
        #expect(entity.set(value: 4, for: \Health.hp))
    }

    @Test func writableKeyPathOnDestroyedEntityReturnsFalse() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let stale = nexus.createEntity()
        stale.destroy()
        #expect(!stale.set(value: 4, for: \Health.hp))
        #expect(nexus.numComponents == 0)
    }

    // MARK: set and remove

    @Test func setReplacesAnExistingComponent() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health(hp: 1))
        let replacement = Health(hp: 2)
        entity.set(replacement)
        #expect(entity.get(Health.self) == replacement)
        #expect(entity.numComponents == 1)
    }

    @Test func removeReturnsWhetherAComponentWasRemoved() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        #expect(entity.remove(Health.self))
        #expect(!entity.remove(Health.self))
        entity.set(Health())
        #expect(entity.remove(Health()))
        #expect(!entity.remove(Health.identifier))
    }

    @Test func removeOfDestroyedEntityReturnsFalse() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let stale = nexus.createEntity(with: Health())
        stale.destroy()
        #expect(!stale.remove(Health.self))
    }

    // MARK: events

    @Test func eventsPerOperation() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        nexus.delegate = recorder
        let entity = nexus.createEntity()

        entity.set(Health())
        #expect(recorder.names == ["added"])
        entity.set(Health())
        #expect(recorder.names == ["added", "replaced"])
        entity.modify(Health.self) { $0.hp = 1 }
        #expect(recorder.names == ["added", "replaced", "modified"])
        lower(&entity[Health.self])
        #expect(recorder.names.last == "modified")
        #expect(recorder.names.count == 4)
        entity.modify(Counter.self, default: Counter()) { $0.value = 1 }
        #expect(Array(recorder.names.suffix(2)) == ["added", "modified"])
        entity.modify(Counter.self, default: Counter()) { $0.value = 2 }
        #expect(recorder.names.last == "modified")
        #expect(recorder.names.count == 7)
        bump(&entity[Counter.self, default: Counter()])
        #expect(recorder.names.count == 8)
        entity.remove(Counter.self)
        #expect(recorder.names.last == "removed")
        // nothing happened: no events
        entity.remove(Counter.self)
        entity.modify(Counter.self) { _ in }
        _ = entity[Counter.self]
        _ = entity[Counter.self, default: Counter()]
        #expect(recorder.names.count == 9)
    }

    @Test func subscribingToStructuralEventsOnlyHidesValueChanges() {
        final class Structural: NexusEventDelegate, @unchecked Sendable {
            var count = 0
            func nexusEvent(_: NexusEvent) { count += 1 }
            func nexusNonFatalError(_: String) {}
        }
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let delegate = Structural()
        nexus.delegate = delegate
        let entity = nexus.createEntity()
        let base = delegate.count
        entity.set(Health())
        entity.set(Health())
        entity.modify(Health.self) { $0.hp = 1 }
        entity[Health.self]?.hp = 5
        #expect(delegate.count == base + 1)
    }

    // MARK: components(_:writing:)

    @Test func componentsReadsCopiesAndWritesInPlace() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Position(x: 2, y: 3), Speed(dx: 1, dy: 1))
        #expect(entity.components(Position.self, writing: Speed.self) { pos, speed in
            speed.dx += pos.x
            speed.dy += pos.y
        })
        #expect(entity.get(Speed.self)?.dx == 3)
        #expect(entity.get(Speed.self)?.dy == 4)
    }

    @Test func componentsWritesSeveralComponents() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Position(x: 0, y: 0), Speed(dx: 1, dy: 2), Health())
        #expect(entity.components(writing: Speed.self, Health.self) { speed, health in
            speed.dx = 10
            health.hp = 10
        })
        #expect(entity.components(Position.self, Health.self, writing: Speed.self, Position.self) { _, _, speed, pos in
            speed.dy = 20
            pos.x = 5
        })
        #expect(entity.get(Speed.self)?.dx == 10)
        #expect(entity.get(Speed.self)?.dy == 20)
        #expect(entity.get(Health.self)?.hp == 10)
        #expect(entity.get(Position.self)?.x == 5)
    }

    @Test func componentsWithAMissingComponentDoesNothing() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        let entity = nexus.createEntity(with: Position(x: 1, y: 1))
        nexus.delegate = recorder
        var called = false
        #expect(!entity.components(Position.self, writing: Speed.self) { _, _ in called = true })
        #expect(!entity.components(Speed.self, writing: Position.self) { _, _ in called = true })
        #expect(!called)
        #expect(recorder.names.isEmpty)
    }

    @Test func componentsEmitsModifiedPerWrittenComponent() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let recorder = Recorder()
        let entity = nexus.createEntity(with: Position(x: 1, y: 1), Speed(dx: 0, dy: 0))
        nexus.delegate = recorder
        entity.components(Position.self, writing: Speed.self) { _, _ in }
        #expect(recorder.names == ["modified"])
        entity.components(writing: Position.self, Speed.self) { _, _ in }
        #expect(recorder.names == ["modified", "modified", "modified"])
    }

    @Test func componentsOfDestroyedEntityReturnsFalse() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let stale = nexus.createEntity(with: Position(x: 1, y: 1), Speed(dx: 0, dy: 0))
        stale.destroy()
        #expect(!stale.components(Position.self, writing: Speed.self) { _, _ in })
    }

    // MARK: copy semantics

    /// The 2.0 contract: `get` is a copy, so changing a `var` copy never changes the entity; only `set` and
    /// `modify` do.
    @Test func valueCopyIsDetached() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        var health = entity.get(Health.self)!
        hurt(&health)
        #expect(entity.get(Health.self)?.hp == 100)
        entity.set(health)
        #expect(entity.get(Health.self)?.hp == 90)
    }

    /// The hazard of plain iteration: the loop variables are copies, so `for var` compiles and silently changes nothing.
    /// Writes go through `modify`, `set` or the subscripts of the entity.
    @Test func mutatingTheLoopVariableOfAFamilyChangesNothing() {
        let nexus = makeNexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Speed(dx: 1, dy: 2))
        let family = nexus.family(requires: Speed.self)
        for var speed in family {
            speed.dx += 10
            #expect(speed.dx == 11)
        }
        #expect(entity.get(Speed.self)?.dx == 1)

        for (member, var speed) in family.entityAndComponents {
            speed.dx += 10
            member.set(speed)
        }
        #expect(entity.get(Speed.self)?.dx == 11)
    }
}

// Misuse inside a modify closure traps. Each case runs in a child process; exit tests are unavailable on iOS, tvOS,
// watchOS and WebAssembly. Exit test bodies cannot capture context, so each trap is a free function.
#if os(macOS) || os(Linux) || os(Windows)

    private func trapMessage(_ result: ExitTest.Result?, _ message: String) {
        #if DEBUG
            let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
            #expect(stderr.contains(message))
        #endif
    }

    private func addingInsideModifyTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health(), Counter())
        entity.modify(Health.self) { _ in entity.set(Speed(dx: 0, dy: 0)) }
    }

    private func removingInsideModifyTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health(), Counter())
        entity.modify(Health.self) { _ in entity.remove(Counter.self) }
    }

    private func replacingInsideModifyTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health(), Counter())
        entity.modify(Health.self) { _ in entity.set(Counter()) }
    }

    private func destroyingInsideModifyTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity.modify(Health.self) { _ in entity.destroy() }
    }

    private func creatingInsideSubscriptModifyTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        func create(_ health: inout Health?) { entity.createEntity() }
        create(&entity[Health.self])
    }

    private func readingTheModifiedComponentTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity.modify(Health.self) { _ in _ = entity.get(Health.self) }
    }

    private func nestedModifyOfTheSameTypeTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity.modify(Health.self) { _ in entity.modify(Health.self) { _ in } }
    }

    private func writingTheSameTypeTwiceTrapsBody() {
        let nexus = Nexus()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity(with: Health())
        entity.components(writing: Health.self, Health.self) { _, _ in }
    }

    @Suite struct MutationTrapTests {
        @Test func addingInsideModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                addingInsideModifyTrapsBody()
            }
            trapMessage(result, "structural change")
        }

        @Test func removingInsideModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                removingInsideModifyTrapsBody()
            }
            trapMessage(result, "structural change")
        }

        @Test func replacingInsideModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                replacingInsideModifyTrapsBody()
            }
            trapMessage(result, "structural change")
        }

        @Test func destroyingInsideModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                destroyingInsideModifyTrapsBody()
            }
            trapMessage(result, "structural change")
        }

        @Test func creatingInsideSubscriptModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                creatingInsideSubscriptModifyTrapsBody()
            }
            trapMessage(result, "structural change")
        }

        @Test func readingTheModifiedComponentTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                readingTheModifiedComponentTrapsBody()
            }
            trapMessage(result, "during a write access")
        }

        @Test func nestedModifyOfTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                nestedModifyOfTheSameTypeTrapsBody()
            }
            trapMessage(result, "nested write access")
        }

        @Test func writingTheSameTypeTwiceTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                writingTheSameTypeTwiceTrapsBody()
            }
            trapMessage(result, "nested write access")
        }
    }
#endif
