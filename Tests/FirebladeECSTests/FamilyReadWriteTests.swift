//
//  FamilyReadWriteTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Marker: Component, Sendable {}

private struct Boom: Error {}

/// Records events of a delegate subscribed to everything.
private final class Recorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var events: [NexusEvent] = []
    var subscribedEvents: NexusEventMask { .all }
    func nexusEvent(_ event: NexusEvent) { events.append(event) }
    func nexusNonFatalError(_: String) {}

    var modified: [ComponentsModified] { events.compactMap { $0 as? ComponentsModified } }
}

/// `count` entities with `Comp1 ... Comp8` all holding the entity's number, plus a `Marker` on the even ones.
private func makeNexus(count: Int) -> Nexus {
    let nexus = Nexus()
    for number in 0 ..< count {
        let entity = nexus.createEntity(with: Comp1(number), Comp2(number), Comp3(number), Comp4(number))
        entity.set(Comp5(number), Comp6(number), Comp7(number), Comp8(number))
        if number.isMultiple(of: 2) {
            entity.set(Marker())
        }
    }
    return nexus
}

@Suite struct FamilyReadWriteTests {
    @Test func readingAndWritingChangesTheStorageInPlace() {
        let nexus = makeNexus(count: 10)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var visited = 0
        family.forEach(reading: Comp1.self, writing: Comp2.self) { read, write in
            write.value = read.value * 10
            visited += 1
        }
        #expect(visited == 10)
        for entity in family.entities {
            let number = entity.get(Comp1.self)?.value
            #expect(entity.get(Comp2.self)?.value == number.map { $0 * 10 })
        }
    }

    @Test func excludedMembersAreNotVisited() {
        let nexus = makeNexus(count: 10)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, excludesAll: Marker.self)
        var seen: [Int] = []
        family.forEach(reading: Comp1.self, writing: Comp2.self) { read, write in
            seen.append(read.value)
            write.value = -1
        }
        #expect(seen.sorted() == [1, 3, 5, 7, 9])
        #expect(nexus.family(requiresAll: Comp2.self, excludesAll: Marker.self).allSatisfy { $0.value == -1 })
        #expect(nexus.family(requiresAll: Comp2.self, Marker.self).allSatisfy { $0.0.value >= 0 })
    }

    @Test func familyOverSubsetOfAStorageTouchesOnlyMembers() {
        let nexus = makeNexus(count: 10)
        let family = nexus.family(requiresAll: Comp1.self, Marker.self)
        family.forEach(writing: Comp1.self) { $0.value += 100 }
        let all = nexus.family(requires: Comp1.self).map(\.value).sorted()
        #expect(all == [100, 1, 102, 3, 104, 5, 106, 7, 108, 9].sorted())
    }

    @Test func emptyFamilyNeverCallsBody() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEach(reading: Comp1.self, writing: Comp2.self) { _, _ in Issue.record("called") }
        family.forEach(writing: Comp1.self) { _ in Issue.record("called") }
    }

    @Test func zeroReadsAndFourReadsWithoutWrites() {
        let nexus = makeNexus(count: 4)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        var sum = 0
        family.forEach(reading: Comp1.self, Comp2.self, Comp3.self, Comp4.self) { a, b, c, d in
            sum += a.value + b.value + c.value + d.value
        }
        #expect(sum == 4 * (0 + 1 + 2 + 3))
        family.forEach(writing: Comp1.self, Comp2.self, Comp3.self, Comp4.self) { a, b, c, d in
            a.value = 1; b.value = 2; c.value = 3; d.value = 4
        }
        #expect(family.allSatisfy { $0.0.value == 1 && $0.1.value == 2 && $0.2.value == 3 && $0.3.value == 4 })
    }

    @Test func fourReadsAndFourWrites() {
        let nexus = makeNexus(count: 5)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        family.forEach(reading: Comp1.self, Comp2.self, Comp3.self, Comp4.self,
                       writing: Comp5.self, Comp6.self, Comp7.self, Comp8.self) { r1, r2, r3, r4, w1, w2, w3, w4 in
            w1.value = r1.value + 1
            w2.value = r2.value + 2
            w3.value = r3.value + 3
            w4.value = r4.value + 4
        }
        for entity in family.entities {
            let number = entity.get(Comp1.self)?.value ?? -1
            #expect(entity.get(Comp5.self)?.value == number + 1)
            #expect(entity.get(Comp6.self)?.value == number + 2)
            #expect(entity.get(Comp7.self)?.value == number + 3)
            #expect(entity.get(Comp8.self)?.value == number + 4)
        }
    }

    @Test func mixedArities() {
        let nexus = makeNexus(count: 5)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        family.forEach(reading: Comp1.self, Comp2.self, writing: Comp3.self, Comp4.self, Comp5.self) { r1, r2, w1, w2, w3 in
            w1.value = r1.value + r2.value
            w2.value = w1.value
            w3.value = -w1.value
        }
        family.forEach(reading: Comp1.self, Comp2.self, Comp3.self, writing: Comp4.self, Comp5.self) { r1, _, r3, w1, w2 in
            #expect(r3.value == 2 * r1.value)
            #expect(w1.value == r3.value)
            w2.value = 7
        }
        #expect(family.allSatisfy { $0.4.value == 7 })
    }

    @Test func parameterPackFallbackReadsAndWrites() {
        let nexus = makeNexus(count: 6)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        // 3 reads and 5 writes: above the generated arity
        family.forEach(reading: Comp1.self, Comp2.self, Comp3.self,
                       writing: Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self) { (written: inout (Comp4, Comp5, Comp6, Comp7, Comp8), r1, r2, r3) in
            let sum = r1.value + r2.value + r3.value
            written.0.value = sum
            written.1.value = sum + 1
            written.2.value = sum + 2
            written.3.value = sum + 3
            written.4.value = sum + 4
        }
        for entity in family.entities {
            let number = entity.get(Comp1.self)?.value ?? -1
            #expect(entity.get(Comp4.self)?.value == 3 * number)
            #expect(entity.get(Comp8.self)?.value == 3 * number + 4)
        }
        // 5 reads and 2 writes
        var visited = 0
        family.forEach(reading: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self,
                       writing: Comp7.self, Comp8.self) { (written: inout (Comp7, Comp8), r1, _, _, _, r5) in
            written.0.value = r1.value
            written.1.value = r5.value + 100
            visited += 1
        }
        #expect(visited == 6)
        #expect(family.allSatisfy { $0.6.value == $0.0.value && $0.7.value == $0.4.value + 100 })
    }

    @Test func oneModifiedEventPerWrittenTypeAndPass() throws {
        let nexus = makeNexus(count: 10)
        let recorder = Recorder()
        nexus.delegate = recorder
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        family.forEach(reading: Comp1.self, writing: Comp2.self, Comp3.self) { _, write2, write3 in
            write2.value += 1
            write3.value += 1
        }
        let modified = recorder.modified
        #expect(modified.count == 2)
        #expect(modified.map(\.count) == [10, 10])
        #expect(modified.map(\.component) == [Comp2.identifier, Comp3.identifier])

        // reads only: no event, and an empty pass: no event
        family.forEach(reading: Comp1.self) { _ in }
        nexus.family(requiresAll: Comp1.self, Marker.self, excludesAll: Comp2.self).forEach(writing: Comp1.self) { _ in }
        #expect(recorder.modified.count == 2)
    }

    @Test func noEventsWithoutValueChangeSubscription() {
        final class Structural: NexusEventDelegate, @unchecked Sendable {
            var count = 0
            func nexusEvent(_: NexusEvent) { count += 1 }
            func nexusNonFatalError(_: String) {}
        }
        let nexus = makeNexus(count: 3)
        let family = nexus.family(requiresAll: Comp1.self)
        let delegate = Structural()
        nexus.delegate = delegate
        family.forEach(writing: Comp1.self) { $0.value = 0 }
        #expect(delegate.count == 0)
    }

    @Test func throwingEndsThePassAndReleasesTheLocks() throws {
        let nexus = makeNexus(count: 10)
        let recorder = Recorder()
        nexus.delegate = recorder
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var visited = 0
        #expect(throws: Boom.self) {
            try family.forEach(reading: Comp1.self, writing: Comp2.self) { _, write in
                write.value = -1
                visited += 1
                if visited == 3 {
                    throw Boom()
                }
            }
        }
        #expect(visited == 3)
        #expect(recorder.modified.map(\.count) == [3])
        // structural changes and nested writes work again
        nexus.createEntity(with: Comp1(99), Comp2(99))
        family.forEach(writing: Comp2.self) { $0.value = 5 }
        #expect(family.allSatisfy { $0.1.value == 5 })
    }

    @Test func readsOfOtherTypesAndNestedReadPassesAreAllowed() {
        let nexus = makeNexus(count: 4)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var pairs = 0
        family.forEach(reading: Comp1.self, writing: Comp2.self) { outer, write in
            family.forEach(reading: Comp1.self) { inner in
                if inner.value == outer.value { pairs += 1 }
            }
            write.value = 0
        }
        #expect(pairs == 4)
    }

    @Test func familiesCreatedAfterwardsAndNewMembersAreIncluded() {
        let nexus = makeNexus(count: 3)
        let family = nexus.family(requiresAll: Comp1.self)
        nexus.createEntity(with: Comp1(10))
        var seen: [Int] = []
        family.forEach(reading: Comp1.self) { seen.append($0.value) }
        #expect(seen.sorted() == [0, 1, 2, 10])
    }

    // MARK: Entity

    @Test func entityComponentsMatrix() {
        let nexus = makeNexus(count: 1)
        let entity = nexus.family(requires: Comp1.self).entities.first { _ in true }
        let subject = entity.unsafelyUnwrapped
        #expect(subject.components(Comp1.self, Comp2.self, Comp3.self, Comp4.self, writing: Comp5.self, Comp6.self, Comp7.self, Comp8.self) { r1, r2, r3, r4, w1, w2, w3, w4 in
            w1.value = r1.value + 1; w2.value = r2.value + 2; w3.value = r3.value + 3; w4.value = r4.value + 4
        })
        #expect(subject.get(Comp8.self)?.value == 4)
        #expect(subject.components(writing: Comp1.self, Comp2.self, Comp3.self, Comp4.self) { a, b, c, d in
            a.value = 1; b.value = 2; c.value = 3; d.value = 4
        })
        #expect(subject.get(Comp4.self)?.value == 4)
        var sum = 0
        #expect(subject.components(Comp1.self, Comp2.self, Comp3.self, Comp4.self) { sum += $0.value + $1.value + $2.value + $3.value })
        #expect(sum == 10)
        #expect(subject.components(Comp1.self, Comp2.self, writing: Comp3.self, Comp4.self, Comp5.self) { a, b, c, d, e in
            c.value = a.value + b.value; d.value = c.value; e.value = d.value
        })
        #expect(subject.get(Comp5.self)?.value == 3)
    }

    @Test func entityComponentsFailsWhenAComponentIsMissing() {
        let nexus = makeNexus(count: 1)
        let entity = nexus.createEntity(with: Comp1(1))
        #expect(!entity.components(Comp1.self, writing: Comp2.self) { _, _ in Issue.record("called") })
        #expect(!entity.components(Comp2.self) { _ in Issue.record("called") })
    }

    @Test func entityParameterPackFallback() throws {
        let nexus = makeNexus(count: 1)
        let recorder = Recorder()
        nexus.delegate = recorder
        let entity = try #require(nexus.family(requires: Comp1.self).entities.first { _ in true })
        let done = entity.components(Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self,
                                     writing: Comp6.self, Comp7.self) { (written: inout (Comp6, Comp7), r1, _, _, _, r5) in
            written.0.value = r1.value + 10
            written.1.value = r5.value + 20
        }
        #expect(done)
        #expect(entity.get(Comp6.self)?.value == 10)
        #expect(entity.get(Comp7.self)?.value == 20)
        let modified = recorder.events.compactMap { $0 as? ComponentModified }
        #expect(modified.map(\.component) == [Comp6.identifier, Comp7.identifier])

        // throwing keeps the write and releases the access
        #expect(throws: Boom.self) {
            try entity.components(Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self,
                                  writing: Comp6.self) { (written: inout Comp6, _, _, _, _, _) in
                written.value = 77
                throw Boom()
            }
        }
        #expect(entity.get(Comp6.self)?.value == 77)
        entity.set(Comp6(1))
    }
}
