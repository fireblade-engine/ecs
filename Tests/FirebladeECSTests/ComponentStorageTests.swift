//
//  ComponentStorageTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

import Testing
@testable import FirebladeECS

/// Components with hand-assigned indices around the old limit of 256, and far above it.
private struct AtIndex255: Component, Sendable {
    static let componentIndex = 255
}

private struct AtIndex256: Component, Sendable {
    static let componentIndex = 256
}

private struct AtIndex1000: Component, Sendable {
    static let componentIndex = 1000
}

/// Counts the live boxes owned by `Token` values to see that storages release what they hold.
private final class LiveBox: Sendable {
    nonisolated(unsafe) static var live = 0

    init() {
        Self.live += 1
    }

    deinit {
        Self.live -= 1
    }
}

private struct Token: Component {
    static var live: Int { LiveBox.live }
    let value: Int
    let box = LiveBox()

    init(_ value: Int = 0) {
        self.value = value
    }
}

extension Nexus.Backend {
    @discardableResult
    fileprivate func remove<C: Component>(_: C.Type, from entityId: EntityIdentifier) -> Bool {
        remove(componentIndex: C.componentIndex, from: entityId)
    }
}

private func entityId(_ index: UInt32, generation: UInt32 = 0) -> EntityIdentifier {
    EntityIdentifier(index: index, generation: generation)
}

@Suite(.serialized)
struct ComponentStorageTests {
    typealias Storage = Nexus.Backend

    private func makeStorage(_ kind: Nexus.StorageKind, entities count: Int) -> (Storage, [EntityIdentifier]) {
        let storage = Storage(kind)
        let ids = (1 ... count).map { entityId(UInt32($0)) }
        for id in ids {
            storage.insertEntity(id)
        }
        return (storage, ids)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func setGetReplaceRemove(_ kind: Nexus.StorageKind) throws {
        let (storage, ids) = makeStorage(kind, entities: 1)
        let id = ids[0]
        #expect(storage.get(Position.self, for: id) == nil)
        #expect(!storage.has(componentIndex: Position.componentIndex, for: id))

        let first = Position(x: 1, y: 2)
        storage.set(first, for: id)
        #expect(storage.get(Position.self, for: id) == first)
        #expect(storage.has(componentIndex: Position.componentIndex, for: id))

        let second = Position(x: 3, y: 4)
        storage.set(second, for: id)
        #expect(storage.get(Position.self, for: id) == second)

        #expect(storage.remove(Position.self, from: id))
        #expect(!storage.remove(Position.self, from: id))
        #expect(storage.get(Position.self, for: id) == nil)
        #expect(storage.componentCount(of: id) == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func swapRemoveKeepsOtherEntitiesIntact(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 10)
        for (offset, id) in ids.enumerated() {
            storage.set(Position(x: offset, y: 0), for: id)
            storage.set(Name(name: "entity \(offset)"), for: id)
        }
        // Removing the first, a middle and the last component forces swap-removes in every position.
        let victims = [0, 5, 9]
        for victim in victims {
            #expect(storage.remove(Position.self, from: ids[victim]))
        }
        for (offset, id) in ids.enumerated() {
            #expect(storage.get(Position.self, for: id)?.x == (victims.contains(offset) ? nil : offset))
            #expect(storage.get(Name.self, for: id)?.name == "entity \(offset)")
        }
        #expect(storage.totalComponentCount == 7 + 10)
    }

    private func makeSparseSet(entities count: Int) -> (Nexus.SparseSetStorage, [EntityIdentifier]) {
        let storage = Nexus.SparseSetStorage()
        let ids = (1 ... count).map { entityId(UInt32($0)) }
        for id in ids {
            storage.insertEntity(id)
        }
        return (storage, ids)
    }

    @Test func pagedSparseIndexGrowsBeyondTheFirstPage() {
        let index = Nexus.PagedSparseIndex()
        let page = UInt32(Nexus.PagedSparseIndex.pageSize)
        #expect(index.slot(of: 0) == -1)
        #expect(index.slot(of: 5 * page) == -1)
        index.set(0, slot: 0)
        index.set(page - 1, slot: 1)
        index.set(page, slot: 2)
        index.set(40 * page + 7, slot: 3)
        #expect([0, page - 1, page, 40 * page + 7].map { index.slot(of: $0) } == [0, 1, 2, 3])
        #expect(index.slot(of: 1) == -1)
        #expect(index.slot(of: 40 * page + 8) == -1)
        #expect(index.allocatedPageCount == 3)
        index.clear(0)
        #expect(index.slot(of: 0) == -1)
        index.set(0, slot: 9)
        #expect(index.slot(of: 0) == 9)
    }

    /// The paged sparse index is internal to the sparse-set storage.
    @Test func pagingBoundaries() {
        let page = Int(Nexus.PagedSparseIndex.pageSize)
        let storage = Nexus.SparseSetStorage()
        let probes = [1, page - 1, page, 2 * page - 1, 2 * page, 3 * page + 5]
        for probe in probes {
            let id = entityId(UInt32(probe))
            storage.insertEntity(id)
            storage.set(Position(x: probe, y: 0), for: id)
        }
        for probe in probes {
            #expect(storage.get(Position.self, for: entityId(UInt32(probe)))?.x == probe)
        }
        let positions = storage.existing(Position.self)
        #expect(positions?.sparse.allocatedPageCount == 4)
        // Neighbours on either side of a boundary have no component.
        for neighbour in [2, page - 2, page + 1, 2 * page + 1] {
            let id = entityId(UInt32(neighbour))
            storage.insertEntity(id)
            #expect(storage.get(Position.self, for: id) == nil)
        }
        #expect(storage.remove(Position.self, from: entityId(UInt32(page))))
        for probe in probes where probe != page {
            #expect(storage.get(Position.self, for: entityId(UInt32(probe)))?.x == probe)
        }
        storage.set(Position(x: -1, y: 0), for: entityId(UInt32(page)))
        #expect(storage.get(Position.self, for: entityId(UInt32(page)))?.x == -1)
    }

    /// The dense buffer of a component type is internal to the sparse-set storage.
    @Test func growthAndReallocation() {
        let count = 5000 // several buffer doublings and two sparse pages
        let (storage, ids) = makeSparseSet(entities: count)
        for (offset, id) in ids.enumerated() {
            storage.set(Position(x: offset, y: 0), for: id)
            if offset.isMultiple(of: 3) {
                storage.set(Comp1(offset), for: id)
            }
            if offset % 7 == 0, offset > 0 {
                #expect(storage.remove(Position.self, from: ids[offset / 2]))
                storage.set(Position(x: offset / 2, y: 0), for: ids[offset / 2])
            }
        }
        for (offset, id) in ids.enumerated() {
            #expect(storage.get(Position.self, for: id)?.x == offset)
            #expect(storage.get(Comp1.self, for: id)?.value == (offset.isMultiple(of: 3) ? offset : nil))
        }
        #expect(storage.existing(Position.self)?.capacity ?? 0 >= count)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func componentsAreReleasedWithTheStorage(_ kind: Nexus.StorageKind) {
        let base = Token.live
        do {
            let (storage, ids) = makeStorage(kind, entities: 50)
            for (offset, id) in ids.enumerated() {
                storage.set(Token(offset), for: id)
            }
            #expect(Token.live == base + 50)
            for id in ids.prefix(10) {
                storage.set(Token(), for: id) // replace: the old token is released
            }
            #expect(Token.live == base + 50)
            for id in ids.prefix(20) {
                #expect(storage.remove(Token.self, from: id))
            }
            #expect(Token.live == base + 30)
            for id in ids.suffix(10) {
                storage.destroyEntity(id)
            }
            #expect(Token.live == base + 20)
        }
        #expect(Token.live == base)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func equalValuesOfSeveralEntitiesAreStoredAsIndependentCopies(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 3)
        let shared = Position(x: 7, y: 7)
        for id in ids {
            storage.set(shared, for: id)
        }
        #expect(ids.allSatisfy { storage.get(Position.self, for: $0) == shared })
        #expect(storage.modify(Position.self, for: ids[1]) { $0.x = 8 })
        #expect(storage.get(Position.self, for: ids[0]) == shared)
        #expect(storage.get(Position.self, for: ids[1]) == Position(x: 8, y: 7))
        #expect(storage.get(Position.self, for: ids[2]) == shared)
        storage.remove(Position.self, from: ids[1])
        #expect(storage.get(Position.self, for: ids[0]) == shared)
        #expect(storage.get(Position.self, for: ids[2]) == shared)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func deadAndStaleEntitiesReportAbsence(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 2)
        storage.set(Position(x: 1, y: 1), for: ids[0])
        let stale = entityId(ids[0].index, generation: 1)
        #expect(storage.get(Position.self, for: stale) == nil)
        #expect(!storage.isAlive(stale))
        #expect(!storage.remove(Position.self, from: stale))
        #expect(!storage.modify(Position.self, for: stale) { _ in })
        #expect(storage.anyComponent(componentIndex: Position.componentIndex, for: stale) == nil)

        #expect(storage.destroyEntity(ids[0]))
        #expect(!storage.destroyEntity(ids[0]))
        #expect(storage.get(Position.self, for: ids[0]) == nil)
        #expect(storage.entityCount == 1)
        // the freed slot holds no component of the former entity once it is reused
        let reused = entityId(ids[0].index, generation: 1)
        storage.insertEntity(reused)
        #expect(storage.get(Position.self, for: reused) == nil)
        #expect(storage.get(Position.self, for: ids[0]) == nil)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func outOfRangeComponentIndicesAreAbsent(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 1)
        storage.set(Position(x: 1, y: 1), for: ids[0])
        for index in [-1, 100_000, Int.max] {
            #expect(!storage.has(componentIndex: index, for: ids[0]))
            #expect(!storage.hasStorage(for: index))
            #expect(storage.anyComponent(componentIndex: index, for: ids[0]) == nil)
            #expect(storage.identifier(ofComponentIndex: index) == nil)
        }
    }

    @Test(arguments: Nexus.StorageKind.allCases) func noLimitOnTheNumberOfComponentTypes(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 2)
        let id = ids[0]
        storage.set(AtIndex255(), for: id)
        storage.set(AtIndex256(), for: id)
        storage.set(AtIndex1000(), for: id)
        storage.set(Position(x: 1, y: 1), for: ids[1])
        #expect(storage.get(AtIndex255.self, for: id) != nil)
        #expect(storage.get(AtIndex256.self, for: id) != nil)
        #expect(storage.get(AtIndex1000.self, for: id) != nil)
        #expect(storage.get(AtIndex1000.self, for: ids[1]) == nil)
        #expect(storage.componentIndices(of: id) == [255, 256, 1000])
        #expect(storage.identifier(ofComponentIndex: 1000) == AtIndex1000.identifier)
        #expect(storage.remove(AtIndex256.self, from: id))
        #expect(storage.componentIndices(of: id) == [255, 1000])
    }

    @Test(arguments: Nexus.StorageKind.allCases) func nestedAccessToDifferentTypesSeesRealData(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 2)
        storage.set(Position(x: 1, y: 1), for: ids[0])
        storage.set(Position(x: 2, y: 2), for: ids[1])
        storage.set(Name(name: "a"), for: ids[0])
        var seen: [String?] = []
        let modified = storage.modify(Position.self, for: ids[0]) { position in
            position.x = 10
            seen.append(storage.get(Name.self, for: ids[0])?.name)
            _ = storage.modify(Name.self, for: ids[0]) { $0.name = "b" }
            seen.append(storage.get(Name.self, for: ids[0])?.name)
        }
        #expect(modified)
        #expect(seen == ["a", "b"])
        #expect(storage.get(Position.self, for: ids[0])?.x == 10)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func bulkAccessCoversEveryComponentOnce(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 20)
        for (offset, id) in ids.enumerated() where offset.isMultiple(of: 2) {
            storage.set(Position(x: offset, y: 0), for: id)
        }
        var count = 0
        var sum = 0
        storage.withComponents(of: Position.self) { entityIndices, positions in
            count = positions.count
            #expect(entityIndices.count == positions.count)
            for position in positions {
                sum += position.x
            }
        }
        #expect(count == 10)
        #expect(sum == (0 ..< 20).filter { $0.isMultiple(of: 2) }.reduce(0, +))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func removeAllForgetsEntitiesAndTypes(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 3)
        storage.set(Position(x: 1, y: 1), for: ids[0])
        storage.removeAll()
        #expect(storage.entityCount == 0)
        #expect(storage.totalComponentCount == 0)
        #expect(storage.get(Position.self, for: ids[0]) == nil)
        #expect(!storage.isAlive(ids[0]))
    }

    @Test(arguments: Nexus.StorageKind.allCases) func untypedSlowPaths(_ kind: Nexus.StorageKind) {
        let (storage, ids) = makeStorage(kind, entities: 1)
        let id = ids[0]
        let position = Position(x: 5, y: 5)
        storage.set(position, for: id)
        storage.set(Name(name: "n"), for: id)
        let indices = storage.componentIndices(of: id)
        #expect(indices == [Position.componentIndex, Name.componentIndex].sorted())
        #expect(storage.anyComponent(componentIndex: Position.componentIndex, for: id) as? Position == position)
        #expect(storage.componentIndex(of: Position.identifier) == Position.componentIndex)
        #expect(storage.remove(componentIndex: Position.componentIndex, from: id))
        #expect(!storage.remove(componentIndex: Position.componentIndex, from: id))
        #expect(storage.componentCount(of: id) == 1)
    }
}
