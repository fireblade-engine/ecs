//
//  ComponentSpanTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Boom: Error {}

private final class Recorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var events: [NexusEvent] = []
    var subscribedEvents: NexusEventMask { .all }
    func nexusEvent(_ event: NexusEvent) { events.append(event) }
    func nexusNonFatalError(_: String) {}

    var modified: [ComponentsModified] { events.compactMap { $0 as? ComponentsModified } }
}

/// `count` entities with `Comp1(number)`, `Comp2(number)` and `Comp3(0)`.
private func makeNexus(_ storage: Nexus.StorageKind, count: Int) -> Nexus {
    let nexus = Nexus(storage: storage)
    for number in 0 ..< count {
        nexus.createEntity(with: Comp1(number), Comp2(number), Comp3(0))
    }
    return nexus
}

@Suite struct ComponentSpanTests {
    // MARK: single type

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func readingSpanSeesAllComponents(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 10)
        var sum = 0
        var count = 0
        nexus.componentSpan(reading: Comp1.self) { (span: Span<Comp1>) in
            count = span.count
            for index in span.indices { sum += span[index].value }
        }
        #expect(count == 10)
        #expect(sum == 45)
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func readingSpanReturnsTheResultOfTheBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 4)
        let total = nexus.componentSpan(reading: Comp1.self) { span in
            var sum = 0
            for index in span.indices { sum += span[index].value }
            return sum
        }
        #expect(total == 6)
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func writingSpanLandsInStorage(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 10)
        nexus.componentSpan(writing: Comp1.self) { (span: inout MutableSpan<Comp1>) in
            for index in span.indices { span[index].value *= 10 }
        }
        let values = nexus.family(requires: Comp1.self).map(\.value).sorted()
        #expect(values == (0 ..< 10).map { $0 * 10 })
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func writingSpanErrorsPropagateAfterTheWrite(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 3)
        let recorder = Recorder()
        nexus.delegate = recorder
        #expect(throws: Boom.self) {
            try nexus.componentSpan(writing: Comp1.self) { span in
                span[0].value = 99
                throw Boom()
            }
        }
        #expect(recorder.modified.count == 1)
        // the lock was released
        nexus.createEntity(with: Comp1(1))
        #expect(nexus.family(requires: Comp1.self).contains { $0.value == 99 })
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func emptyStorageGivesEmptySpansAndNoEvent(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let recorder = Recorder()
        nexus.delegate = recorder
        // a type that never had a storage
        nexus.componentSpan(reading: Comp1.self) { let empty = $0.isEmpty; #expect(empty) }
        nexus.componentSpan(writing: Comp1.self) { let empty = $0.isEmpty; #expect(empty) }
        // a storage that became empty
        let entity = nexus.createEntity(with: Comp2(1))
        entity.remove(Comp2.self)
        nexus.componentSpan(reading: Comp2.self) { let empty = $0.isEmpty; #expect(empty) }
        nexus.componentSpan(writing: Comp2.self) { let empty = $0.isEmpty; #expect(empty) }
        #expect(recorder.modified.isEmpty)
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func spansAfterSwapRemoveChurn(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 10)
        let entities = Array(nexus.family(requires: Comp1.self).entities)
        for entity in entities where entity.get(Comp1.self)!.value.isMultiple(of: 3) {
            entity.remove(Comp1.self)
        }
        var seen: [Int] = []
        nexus.componentSpan(reading: Comp1.self) { span in
            for index in span.indices { seen.append(span[index].value) }
        }
        #expect(seen.sorted() == [1, 2, 4, 5, 7, 8])
        nexus.componentSpan(writing: Comp1.self) { span in
            for index in span.indices { span[index].value += 100 }
        }
        let afterwards = nexus.family(requires: Comp1.self).map(\.value).sorted()
        #expect(afterwards == [101, 102, 104, 105, 107, 108])
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func writingSpanEmitsOneEventPerPass(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 7)
        let recorder = Recorder()
        nexus.delegate = recorder
        nexus.componentSpan(writing: Comp1.self) { span in
            for index in span.indices { span[index].value += 1 }
        }
        #expect(recorder.modified.count == 1)
        #expect(recorder.modified.first?.count == 7)
        #expect(recorder.modified.first?.component == Comp1.identifier)
        nexus.componentSpan(reading: Comp1.self) { _ in }
        #expect(recorder.modified.count == 1)
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func readingOtherTypesAndNestingReadsIsAllowed(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 5)
        var sum = 0
        nexus.componentSpan(writing: Comp1.self) { writing in
            nexus.componentSpan(reading: Comp2.self) { reading in
                for index in writing.indices { writing[index].value = reading[index % reading.count].value }
            }
            sum = nexus.family(requires: Comp3.self).count
        }
        #expect(sum == 5)
        nexus.componentSpan(reading: Comp1.self) { outer in
            nexus.componentSpan(reading: Comp1.self) { inner in
                let same = inner.count == outer.count
                #expect(same)
            }
            // the outer span still locks the type after the inner one ended
            let outerCount = outer.count
            #expect(outerCount == 5)
        }
        // writes are possible again once all read spans ended
        nexus.componentSpan(writing: Comp1.self) { $0[0].value = 1 }
    }

    // MARK: family batches

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansPairElementsOfTheSameMember(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 10)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var visited = 0
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { (reads: Span<Comp1>, writes: inout MutableSpan<Comp2>) in
            let same = reads.count == writes.count
            #expect(same)
            for index in writes.indices {
                writes[index].value = reads[index].value * 10
                visited += 1
            }
        }
        #expect(visited == 10)
        for entity in family.entities {
            #expect(entity.get(Comp2.self)?.value == entity.get(Comp1.self).map { $0.value * 10 })
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansAreOneBatchWhenColumnsAreAligned(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 100)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var calls = 0
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { reads, _ in
            calls += 1
            let readCount = reads.count
            #expect(readCount == 100)
        }
        #expect(calls == 1)
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansAfterChurnVisitEveryMemberOnce(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 40)
        let all = Array(nexus.family(requires: Comp1.self).entities)
        for entity in all where entity.get(Comp1.self)!.value % 5 == 2 {
            entity.remove(Comp3.self)
        }
        for entity in all where entity.get(Comp1.self)!.value % 7 == 3 {
            entity.remove(Comp2.self)
            entity.set(Comp2(entity.get(Comp1.self)!.value))
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        let expected = family.count
        var seen: [Int] = []
        var calls = 0
        family.forEachComponentSpan(reading: Comp1.self, Comp2.self, writing: Comp3.self) { first, second, third in
            calls += 1
            let same = first.count == second.count && second.count == third.count
            #expect(same)
            for index in third.indices {
                let pair = first[index].value == second[index].value
                #expect(pair)
                third[index].value = first[index].value + 1
                seen.append(first[index].value)
            }
        }
        #expect(seen.count == expected)
        #expect(Set(seen).count == expected)
        // the sparse set loses alignment under churn and passes shorter batches; an archetype table is always one batch
        #expect(storage == .archetype ? calls == 1 : calls > 1)
        for entity in family.entities {
            #expect(entity.get(Comp3.self)?.value == entity.get(Comp1.self).map { $0.value + 1 })
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpanOverloads(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 6)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        var sum = 0
        family.forEachComponentSpan(reading: Comp1.self) { first in
            for index in first.indices { sum += first[index].value }
        }
        family.forEachComponentSpan(reading: Comp1.self, Comp2.self) { first, second in
            for index in first.indices { sum += first[index].value + second[index].value }
        }
        #expect(sum == 15 + 30)
        family.forEachComponentSpan(writing: Comp3.self) { span in
            for index in span.indices { span[index].value = 1 }
        }
        family.forEachComponentSpan(writing: Comp2.self, Comp3.self) { second, third in
            for index in third.indices { second[index].value = 5; third[index].value += 1 }
        }
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self, Comp3.self) { first, second, third in
            for index in third.indices { second[index].value += first[index].value; third[index].value += 1 }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansIgnoreNonMembersAndEmptyFamilies(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 6)
        nexus.createEntity(with: Comp1(100))
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        var count = 0
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { first, _ in count += first.count }
        #expect(count == 6)
        let emptyNexus = Nexus(storage: storage)
        let empty = emptyNexus.family(requiresAll: Comp1.self, Comp2.self)
        empty.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { _, _ in Issue.record("called") }
        withExtendedLifetime(emptyNexus) {}
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansEmitOneEventPerWrittenType(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage, count: 9)
        for entity in Array(nexus.family(requires: Comp1.self).entities) where entity.get(Comp1.self)!.value.isMultiple(of: 2) {
            entity.remove(Comp3.self)
        }
        let recorder = Recorder()
        nexus.delegate = recorder
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self, Comp3.self) { _, _, _ in }
        #expect(recorder.modified.count == 2)
        #expect(recorder.modified.allSatisfy { $0.count == family.count })
        #expect(Set(recorder.modified.map(\.component)) == [Comp2.identifier, Comp3.identifier])
        family.forEachComponentSpan(reading: Comp1.self, Comp2.self) { _, _ in }
        #expect(recorder.modified.count == 2)
    }

    // MARK: entities with different component sets

    /// Entities of three component sets (and with them, in the archetype storage, three tables) that all have `Comp1`.
    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func makeMixedNexus(_ storage: Nexus.StorageKind) -> Nexus {
        let nexus = Nexus(storage: storage)
        for number in 0 ..< 4 {
            nexus.createEntity(with: Comp1(number), Comp2(number))
            nexus.createEntity(with: Comp1(10 + number), Comp2(10 + number), Comp3(0))
            nexus.createEntity(with: Comp1(20 + number), Comp4(0))
        }
        return nexus
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func singleSpanOfATypeInSeveralTablesSeesEveryComponent(_ storage: Nexus.StorageKind) {
        let nexus = makeMixedNexus(storage)
        var values: [Int] = []
        nexus.componentSpan(reading: Comp1.self) { (span: Span<Comp1>) in
            for index in span.indices { values.append(span[index].value) }
        }
        let expected = (0 ..< 4).flatMap { [$0, 10 + $0, 20 + $0] }
        #expect(values.sorted() == expected.sorted())
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func singleWritingSpanOfATypeInSeveralTablesWritesEveryComponent(_ storage: Nexus.StorageKind) {
        let nexus = makeMixedNexus(storage)
        let recorder = Recorder()
        nexus.delegate = recorder
        nexus.componentSpan(writing: Comp1.self) { (span: inout MutableSpan<Comp1>) in
            for index in span.indices { span[index].value += 100 }
        }
        var values: [Int] = []
        for entity in nexus.family(requires: Comp1.self).entities { values.append(entity.get(Comp1.self)!.value) }
        let expected = (0 ..< 4).flatMap { [100 + $0, 110 + $0, 120 + $0] }
        #expect(values.sorted() == expected.sorted())
        // one event for the pass, covering the components of all tables
        #expect(recorder.modified.map(\.count) == [12])
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func singleWritingSpanKeepsItsWritesWhenTheBodyThrows(_ storage: Nexus.StorageKind) {
        let nexus = makeMixedNexus(storage)
        #expect(throws: Boom.self) {
            try nexus.componentSpan(writing: Comp1.self) { (span: inout MutableSpan<Comp1>) in
                for index in span.indices { span[index].value = 7 }
                throw Boom()
            }
        }
        for entity in nexus.family(requires: Comp1.self).entities {
            #expect(entity.get(Comp1.self)?.value == 7)
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    @Test(arguments: Nexus.StorageKind.allCases) func familySpansVisitEveryMemberOnceAcrossComponentSets(_ storage: Nexus.StorageKind) {
        let nexus = makeMixedNexus(storage)
        let family = nexus.family(requires: Comp1.self)
        var seen: [Int] = []
        var calls = 0
        family.forEachComponentSpan(writing: Comp1.self) { span in
            calls += 1
            for index in span.indices {
                seen.append(span[index].value)
                span[index].value += 1
            }
        }
        #expect(seen.sorted() == (0 ..< 4).flatMap { [$0, 10 + $0, 20 + $0] }.sorted())
        // the archetype storage passes one batch per table that matches, here one per component set
        if storage == .archetype {
            #expect(calls == 3)
        }
        #expect(family.entities.allSatisfy { $0.get(Comp1.self)!.value % 10 >= 1 })
    }
}
