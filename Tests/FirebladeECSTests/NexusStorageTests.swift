//
//  NexusStorageTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Tag127: Component, Sendable {
    static let componentIndex = 127
}

private struct Tag128: Component, Sendable {
    static let componentIndex = 128
}

private struct Tag300: Component, Sendable {
    static let componentIndex = 300
}

@Suite struct NexusStorageTests {
    @Test func defaultStorageIsTheArchetype() {
        #expect(Nexus.StorageKind.default == .archetype)
        #expect(Nexus.StorageKind.allCases == [.sparseSet, .archetype])
        if case .archetype = Nexus().backend {} else {
            Issue.record("Nexus() does not use the archetype storage")
        }
    }

    @Test(arguments: Nexus.StorageKind.allCases)
    func nexusWorksOnEveryStorage(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let family = nexus.family(requiresAll: Position.self, Name.self, excludesAll: Comp1.self)
        let entity = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "a"))
        let other = nexus.createEntity(with: Position(x: 3, y: 4), Name(name: "b"), Comp1(1))
        #expect(family.entities.map(\.identifier) == [entity.identifier])
        #expect(entity.get(Position.self)?.x == 1)
        #expect(nexus.numComponents == 5)
        other.remove(Comp1.self)
        #expect(family.count == 2)
        nexus.destroy(entity: entity)
        #expect(family.count == 1)
        #expect(nexus.numComponents == 2)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func familiesSpanTheInlineBoundaryOfTheComponentMask(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let family = nexus.family(requiresAll: Tag127.self, Tag300.self, excludesAll: Tag128.self)
        let match = nexus.createEntity(with: Tag127(), Tag300())
        let excluded = nexus.createEntity(with: Tag127(), Tag128(), Tag300())
        let incomplete = nexus.createEntity(with: Tag127(), Tag128())
        #expect(family.entities.map(\.identifier) == [match.identifier])
        #expect(family.canBecomeMember(match))
        #expect(!family.canBecomeMember(excluded))
        #expect(!family.canBecomeMember(incomplete))

        excluded.remove(Tag128.self)
        #expect(family.entities.map(\.identifier) == [match.identifier, excluded.identifier])
        match.remove(Tag300.self)
        #expect(family.entities.map(\.identifier) == [excluded.identifier])
        #expect(match.numComponents == 1)
        #expect(Set(excluded.makeComponentsIterator().map(\.identifier)) == [Tag127.identifier, Tag300.identifier])
    }

    @Test(arguments: Nexus.StorageKind.allCases) func familyCreatedAfterEntitiesFindsComponentsAboveTheInlineBoundary(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity(with: Tag300())
        let family = nexus.family(requires: Tag300.self)
        #expect(family.entities.map(\.identifier) == [entity.identifier])
    }

    @Test(arguments: Nexus.StorageKind.allCases) func traitsFromIdentifiersResolveThroughTheStorage(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity(with: Position(x: 1, y: 1))
        let traits = FamilyTraitSet(requiresAll: [Position.identifier], excludesAll: [Name.identifier])
        #expect(nexus.canBecomeMember(entity, in: traits))
        // required component without storage: nobody can match
        let unknown = FamilyTraitSet(requiresAll: [ComponentIdentifier(id: 12345)], excludesAll: [])
        #expect(!nexus.canBecomeMember(entity, in: unknown))
        // excluded component without storage excludes nothing
        let excludesUnknown = FamilyTraitSet(requiresAll: [Position.identifier], excludesAll: [ComponentIdentifier(id: 12345)])
        #expect(nexus.canBecomeMember(entity, in: excludesUnknown))
        entity.set(Name(name: "x"))
        #expect(!nexus.canBecomeMember(entity, in: traits))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func clearDropsEntitiesComponentsAndFamilies(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let family = nexus.family(requires: Position.self)
        nexus.createEntity(with: Position(x: 1, y: 1))
        nexus.clear()
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numFamilies == 0)
        #expect(family.count == 0)
        // the nexus stays usable
        let entity = nexus.createEntity(with: Position(x: 2, y: 2))
        #expect(entity.get(Position.self)?.x == 2)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func componentIdentifiersOfAnEntityComeFromTheStorage(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity(with: Position(x: 1, y: 1), Name(name: "n"))
        #expect(nexus.get(components: entity.identifier) == [Position.identifier, Name.identifier])
        #expect(nexus.has(componentId: Position.identifier, entityId: entity.identifier))
        #expect(!nexus.has(componentId: Comp1.identifier, entityId: entity.identifier))
        #expect(nexus.count(components: entity.identifier) == 2)
        nexus.destroy(entity: entity)
        #expect(nexus.get(components: entity.identifier) == nil)
    }

    // MARK: structural churn across component sets

    private struct Lcg {
        var state: UInt64
        mutating func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
    }

    /// Adds, replaces and removes components of five types on 200 entities in random order and checks every entity against a model.
    ///
    /// On the archetype storage every step moves rows between tables, which exercises swap-remove and the entity index.
    @Test(arguments: Nexus.StorageKind.allCases)
    func randomStructuralChurnKeepsEveryEntityIntact(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        var random = Lcg(state: 42)
        var entities: [Entity] = []
        var model: [[Int?]] = []
        for _ in 0 ..< 200 {
            entities.append(nexus.createEntity())
            model.append([nil, nil, nil, nil, nil])
        }
        for step in 0 ..< 4000 {
            let index = random.next(entities.count)
            let kind = random.next(5)
            let value = step
            if random.next(3) == 0 {
                switch kind {
                case 0: entities[index].remove(Comp1.self)
                case 1: entities[index].remove(Comp2.self)
                case 2: entities[index].remove(Comp3.self)
                case 3: entities[index].remove(Comp4.self)
                default: entities[index].remove(Name.self)
                }
                model[index][kind] = nil
            } else {
                switch kind {
                case 0: entities[index].set(Comp1(value))
                case 1: entities[index].set(Comp2(value))
                case 2: entities[index].set(Comp3(value))
                case 3: entities[index].set(Comp4(value))
                default: entities[index].set(Name(name: "\(value)"))
                }
                model[index][kind] = value
            }
        }
        var expectedComponents = 0
        for (index, entity) in entities.enumerated() {
            let expected = model[index]
            expectedComponents += expected.compactMap { $0 }.count
            #expect(entity.get(Comp1.self)?.value == expected[0])
            #expect(entity.get(Comp2.self)?.value == expected[1])
            #expect(entity.get(Comp3.self)?.value == expected[2])
            #expect(entity.get(Comp4.self)?.value == expected[3])
            #expect(entity.get(Name.self).map { Int($0.name) } == expected[4].map { .some($0) })
            #expect(entity.numComponents == expected.compactMap { $0 }.count)
        }
        #expect(nexus.numComponents == expectedComponents)
        #expect(nexus.numEntities == 200)
        // families agree with the models, whatever the storage
        let family = nexus.family(requiresAll: Comp1.self, Comp3.self, excludesAll: Comp4.self)
        let expectedMembers = model.indices.filter { model[$0][0] != nil && model[$0][2] != nil && model[$0][3] == nil }
        #expect(Set(family.entities.map(\.identifier)) == Set(expectedMembers.map { entities[$0].identifier }))
        var visited = 0
        family.forEach(reading: Comp1.self, writing: Comp3.self) { first, third in
            #expect(first.value >= 0)
            third.value += 1
            visited += 1
        }
        #expect(visited == expectedMembers.count)
        for index in expectedMembers {
            #expect(entities[index].get(Comp3.self)?.value == model[index][2]! + 1)
        }
    }

    @Test(arguments: Nexus.StorageKind.allCases)
    func familyForEachVisitsMembersOfSeveralComponentSetsOnceAndEmitsOneEvent(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        var ids: [EntityIdentifier] = []
        for number in 0 ..< 5 {
            ids.append(nexus.createEntity(with: Comp1(number), Comp2(0)).identifier)
            ids.append(nexus.createEntity(with: Comp1(number), Comp2(0), Comp3(0)).identifier)
            ids.append(nexus.createEntity(with: Comp1(number), Comp2(0), Comp4(0)).identifier)
            nexus.createEntity(with: Comp1(number), Comp2(0), Comp5(0))
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, excludesAll: Comp5.self)
        let recorder = ValueChangeRecorder()
        nexus.delegate = recorder
        var visited = 0
        family.forEach(reading: Comp1.self, writing: Comp2.self) { first, second in
            second.value = first.value + 1
            visited += 1
        }
        #expect(visited == 15)
        #expect(recorder.counts == [15])
        for id in ids {
            let entity = Entity(nexus: nexus, id: id)
            #expect(entity.get(Comp2.self)?.value == entity.get(Comp1.self).map { $0.value + 1 })
        }
        // the entities with the excluded component keep their value
        #expect(nexus.family(requires: Comp5.self).allSatisfy { $0.value == 0 })
    }

    @Test(arguments: Nexus.StorageKind.allCases)
    func bulkWriteOverSeveralComponentSetsEmitsOneEventWithTheTotal(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        for number in 0 ..< 4 {
            nexus.createEntity(with: Comp1(number))
            nexus.createEntity(with: Comp1(number), Comp2(0))
            nexus.createEntity(with: Comp1(number), Comp3(0))
        }
        let recorder = ValueChangeRecorder()
        nexus.delegate = recorder
        var seen = 0
        nexus.withComponents(of: Comp1.self) { indices, values in
            #expect(indices.count == values.count)
            seen += values.count
        }
        #expect(seen == 12)
        #expect(recorder.counts == [12])
    }

    @Test(arguments: Nexus.StorageKind.allCases)
    func destroyedAndClearedEntitiesReleaseTheirComponents(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entities = (0 ..< 30).map { nexus.createEntity(with: Comp1($0), Name(name: "\($0)")) }
        for entity in entities.prefix(10) {
            nexus.destroy(entity: entity)
        }
        #expect(nexus.numEntities == 20)
        #expect(nexus.numComponents == 40)
        for (offset, entity) in entities.enumerated().dropFirst(10) {
            #expect(entity.get(Comp1.self)?.value == offset)
            #expect(entity.get(Name.self)?.name == "\(offset)")
        }
        nexus.clear()
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
    }

    // MARK: archetype tables

    @Test func archetypeTablesAreSharedByEntitiesWithTheSameComponentSetAndKeptWhenEmpty() throws {
        let nexus = Nexus(storage: .archetype)
        guard case let .archetype(archetype) = nexus.backend else {
            Issue.record("expected the archetype storage")
            return
        }
        // the table of entities without components exists from the start
        #expect(archetype.tableCount == 1)
        let first = nexus.createEntity(with: Comp1(1), Comp2(2))
        let second = nexus.createEntity(with: Comp2(3), Comp1(4))
        // components are added one by one: {Comp1} and {Comp1, Comp2} for the first, {Comp2} and (again) {Comp1, Comp2} for the second
        #expect(archetype.tableCount == 4)
        first.remove(Comp2.self)
        second.remove(Comp2.self)
        // the removal reuses the table {Comp1} through the cached edge
        #expect(archetype.tableCount == 4)
        second.set(Comp2(5))
        first.set(Comp2(6))
        #expect(archetype.tableCount == 4)
        // a table that became empty stays
        nexus.destroy(entity: first)
        nexus.destroy(entity: second)
        #expect(archetype.tableCount == 4)
        #expect(nexus.numComponents == 0)
        // clear forgets the tables
        nexus.clear()
        #expect(archetype.tableCount == 1)
    }

    @Test func archetypeFamilyQueriesAreCachedAndExtendedByNewTables() throws {
        let nexus = Nexus(storage: .archetype)
        guard case let .archetype(archetype) = nexus.backend else {
            Issue.record("expected the archetype storage")
            return
        }
        nexus.createEntity(with: Comp1(1))
        let family = nexus.family(requires: Comp1.self)
        func visit() -> Int {
            var count = 0
            family.forEach(reading: Comp1.self) { _ in count += 1 }
            return count
        }
        // creating the family lists its tables, so the first pass has nothing left to build
        #expect(archetype.queryCache.count == 1)
        let query = try #require(archetype.queryCache.values.first)
        let matching = query.tables.count
        #expect(matching == 1)
        #expect(visit() == 1)
        #expect(archetype.queryCache.values.first === query)
        #expect(visit() == 1)
        // the second pass reuses the query instead of scanning the tables again
        #expect(archetype.queryCache.count == 1)
        #expect(archetype.queryCache.values.first === query)
        #expect(query.tables.count == matching)
        // a new component set creates a table, which the next pass adds to the query
        nexus.createEntity(with: Comp1(2), Comp2(2))
        #expect(visit() == 2)
        #expect(archetype.queryCache.values.first === query)
        #expect(query.tables.count > matching)
    }
}

/// Records the counts of ``ComponentsModified`` events.
private final class ValueChangeRecorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var counts: [Int] = []
    var subscribedEvents: NexusEventMask { .valueChanges }
    func nexusEvent(_ event: NexusEvent) {
        if let modified = event as? ComponentsModified {
            counts.append(modified.count)
        }
    }

    func nexusNonFatalError(_: String) {}
}
