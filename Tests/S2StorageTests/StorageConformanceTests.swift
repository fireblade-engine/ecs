//
//  StorageConformanceTests.swift
//  S2StorageTests
//

import S2Storage
import Testing

// Arity-numbered names mirror the per-arity overloads.
// swiftlint:disable identifier_name file_length

@Suite(.serialized)
struct StorageConformanceTests {
    @Test(arguments: StorageKind.allCases)
    func setGetReplaceRemove(_ kind: StorageKind) {
        kind.run(SetGetReplaceRemove.self)
    }

    @Test(arguments: StorageKind.allCases)
    func modifyInPlace(_ kind: StorageKind) {
        kind.run(ModifyInPlace.self)
    }

    @Test(arguments: StorageKind.allCases)
    func swapRemoveKeepsOtherEntitiesIntact(_ kind: StorageKind) {
        kind.run(SwapRemove.self)
    }

    @Test(arguments: StorageKind.allCases)
    func pagingBoundaries(_ kind: StorageKind) {
        kind.run(PagingBoundaries.self)
    }

    @Test(arguments: StorageKind.allCases)
    func growthAcrossBlocksAndReallocation(_ kind: StorageKind) {
        kind.run(Growth.self)
    }

    @Test(arguments: StorageKind.allCases)
    func nonTrivialFieldsSurviveMovesAndRemoves(_ kind: StorageKind) {
        kind.run(NonTrivialFields.self)
    }

    @Test(arguments: StorageKind.allCases)
    func componentsAreReleasedWithTheStorage(_ kind: StorageKind) {
        let before = Token.live
        kind.run(TokenLifetime.self)
        #expect(Token.live == before)
    }

    @Test(arguments: StorageKind.allCases)
    func rowMovesPreserveOtherComponents(_ kind: StorageKind) {
        kind.run(RowMoves.self)
    }

    @Test(arguments: StorageKind.allCases)
    func familyMembershipWithExcludes(_ kind: StorageKind) {
        kind.run(Membership.self)
    }

    @Test(arguments: StorageKind.allCases)
    func destroyRemovesEverything(_ kind: StorageKind) {
        kind.run(Destroy.self)
    }

    @Test(arguments: StorageKind.allCases)
    func typedIterationAcrossArities(_ kind: StorageKind) {
        kind.run(Iteration.self)
    }

    @Test(arguments: StorageKind.allCases)
    func untypedSlowPaths(_ kind: StorageKind) {
        kind.run(Untyped.self)
    }

    @Test(arguments: StorageKind.allCases)
    func bulkAccessCoversEveryComponentOnce(_ kind: StorageKind) {
        kind.run(Bulk.self)
    }
}

// MARK: - Test bodies

private enum SetGetReplaceRemove: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entity = storage.createEntity()
        #expect(storage.isAlive(entity))
        #expect(storage.get(Position.self, for: entity) == nil)
        #expect(!storage.has(Position.self, for: entity))

        storage.set(Position(x: 1, y: 2), for: entity)
        #expect(storage.get(Position.self, for: entity) == Position(x: 1, y: 2))
        #expect(storage.has(Position.self, for: entity))

        storage.set(Position(x: 3, y: 4), for: entity)
        #expect(storage.get(Position.self, for: entity) == Position(x: 3, y: 4))

        #expect(storage.remove(Position.self, from: entity))
        #expect(!storage.remove(Position.self, from: entity))
        #expect(storage.get(Position.self, for: entity) == nil)
        #expect(!storage.has(Position.self, for: entity))
        #expect(storage.entityCount == 1)
    }
}

private enum ModifyInPlace: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entity = storage.createEntity()
        #expect(!storage.modify(Position.self, for: entity) { $0.x = 1 })
        storage.set(Position(x: 1, y: 1), for: entity)
        #expect(storage.modify(Position.self, for: entity) { $0.x += 41 })
        #expect(storage.get(Position.self, for: entity) == Position(x: 42, y: 1))
    }
}

private enum SwapRemove: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entities = storage.makeEntities(10)
        for (offset, entity) in entities.enumerated() {
            storage.set(Position(x: Double(offset)), for: entity)
            storage.set(Label(text: "entity \(offset)"), for: entity)
        }
        // Removing the first, a middle and the last component forces swap-removes in every position.
        for victim in [0, 5, 9] {
            #expect(storage.remove(Position.self, from: entities[victim]))
        }
        for (offset, entity) in entities.enumerated() {
            let removed = [0, 5, 9].contains(offset)
            #expect(storage.get(Position.self, for: entity) == (removed ? nil : Position(x: Double(offset))))
            #expect(storage.get(Label.self, for: entity) == Label(text: "entity \(offset)"))
        }
        var visited = 0
        storage.forEach(reading: Position.self) { _ in visited += 1 }
        #expect(visited == 7)
    }
}

private enum PagingBoundaries: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let page = PagedSparseIndex.pageSize
        let entities = storage.makeEntities(2 * page + 904)
        let probes = [0, page - 1, page, 2 * page - 1, 2 * page, entities.count - 1]
        for probe in probes {
            storage.set(Position(x: Double(probe)), for: entities[probe])
        }
        for probe in probes {
            #expect(storage.get(Position.self, for: entities[probe]) == Position(x: Double(probe)))
        }
        // Neighbours on either side of a boundary have no component.
        for neighbour in [1, page - 2, page + 1, 2 * page + 1] {
            #expect(storage.get(Position.self, for: entities[neighbour]) == nil)
        }
        #expect(storage.remove(Position.self, from: entities[page]))
        for probe in probes where probe != page {
            #expect(storage.get(Position.self, for: entities[probe]) == Position(x: Double(probe)))
        }
        storage.set(Position(x: -1), for: entities[page])
        #expect(storage.get(Position.self, for: entities[page]) == Position(x: -1))
    }
}

private enum Growth: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let count = 5000 // several blocks of 1024, several array doublings
        var entities: [EntityID] = []
        for offset in 0 ..< count {
            let entity = storage.createEntity()
            entities.append(entity)
            storage.set(Position(x: Double(offset)), for: entity)
            if offset.isMultiple(of: 3) {
                storage.set(Velocity(dx: Double(offset)), for: entity)
            }
            if offset % 7 == 0, offset > 0 {
                #expect(storage.remove(Position.self, from: entities[offset / 2]))
                storage.set(Position(x: Double(offset / 2)), for: entities[offset / 2])
            }
        }
        for offset in 0 ..< count {
            #expect(storage.get(Position.self, for: entities[offset]) == Position(x: Double(offset)))
            #expect(storage.get(Velocity.self, for: entities[offset])?.dx == (offset.isMultiple(of: 3) ? Double(offset) : nil))
        }
    }
}

private enum NonTrivialFields: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entities = storage.makeEntities(200)
        for (offset, entity) in entities.enumerated() {
            storage.set(Label(text: String(repeating: "label-\(offset)-", count: 8)), for: entity)
            storage.set(Samples(values: Array(0 ... offset % 17)), for: entity)
        }
        // Moves: adding and removing unrelated components moves rows (archetype) or swaps slots (sparse set).
        for (offset, entity) in entities.enumerated() {
            if offset.isMultiple(of: 2) {
                storage.set(Position(x: Double(offset)), for: entity)
            }
            if offset.isMultiple(of: 5) {
                storage.set(Frozen(), for: entity)
            }
            if offset.isMultiple(of: 4) {
                #expect(storage.remove(Samples.self, from: entity))
            }
        }
        for (offset, entity) in entities.enumerated() {
            #expect(storage.get(Label.self, for: entity)?.text == String(repeating: "label-\(offset)-", count: 8))
            let samples = storage.get(Samples.self, for: entity)
            #expect(samples == (offset.isMultiple(of: 4) ? nil : Samples(values: Array(0 ... offset % 17))))
        }
        for entity in entities.prefix(100) {
            #expect(storage.destroyEntity(entity))
        }
        for (offset, entity) in entities.enumerated() where offset >= 100 {
            #expect(storage.get(Label.self, for: entity)?.text == String(repeating: "label-\(offset)-", count: 8))
        }
    }
}

private enum TokenLifetime: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let base = Token.live
        let entities = storage.makeEntities(50)
        for entity in entities {
            storage.set(Held(), for: entity)
        }
        #expect(Token.live == base + 50)
        for entity in entities.prefix(10) {
            storage.set(Held(), for: entity) // replace: the old token is released
        }
        #expect(Token.live == base + 50)
        for entity in entities.prefix(10) {
            storage.set(Position(), for: entity) // row moves must not duplicate or drop tokens
        }
        #expect(Token.live == base + 50)
        for entity in entities.prefix(20) {
            #expect(storage.remove(Held.self, from: entity))
        }
        #expect(Token.live == base + 30)
        for entity in entities.suffix(10) {
            storage.destroyEntity(entity)
        }
        #expect(Token.live == base + 20)
    }
}

private enum RowMoves: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entities = storage.makeEntities(6)
        for (offset, entity) in entities.enumerated() {
            storage.set(Position(x: Double(offset)), for: entity)
            storage.set(Label(text: "e\(offset)"), for: entity)
            storage.set(Mass(kilograms: Double(offset)), for: entity)
        }
        storage.set(Velocity(dx: 7), for: entities[2]) // add: row leaves the shared table
        #expect(storage.remove(Label.self, from: entities[3])) // remove: row leaves the shared table
        storage.set(Charge(coulombs: 9), for: entities[0])
        #expect(storage.remove(Mass.self, from: entities[0]))

        for (offset, entity) in entities.enumerated() {
            #expect(storage.get(Position.self, for: entity) == Position(x: Double(offset)))
            #expect(storage.get(Label.self, for: entity) == (offset == 3 ? nil : Label(text: "e\(offset)")))
            #expect(storage.get(Mass.self, for: entity) == (offset == 0 ? nil : Mass(kilograms: Double(offset))))
            #expect(storage.get(Velocity.self, for: entity) == (offset == 2 ? Velocity(dx: 7) : nil))
            #expect(storage.get(Charge.self, for: entity) == (offset == 0 ? Charge(coulombs: 9) : nil))
        }
    }
}

private enum Membership: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entities = storage.makeEntities(30)
        for (offset, entity) in entities.enumerated() {
            storage.set(Position(x: Double(offset)), for: entity)
            if offset % 2 == 0 {
                storage.set(Velocity(dx: 1), for: entity)
            }
            if offset % 3 == 0 {
                storage.set(Frozen(), for: entity)
            }
        }
        let notFrozen = FamilyFilter(excludes: ComponentMask(Frozen.self))
        let frozenOnly = FamilyFilter(requires: ComponentMask(Frozen.self))
        var moving = 0
        storage.forEach(reading: Position.self, Velocity.self, where: notFrozen) { _, _ in moving += 1 }
        #expect(moving == (0 ..< 30).filter { $0 % 2 == 0 && $0 % 3 != 0 }.count)

        var frozen = 0
        storage.forEach(reading: Position.self, where: frozenOnly) { _ in frozen += 1 }
        #expect(frozen == 10)

        var writes = 0
        storage.forEach(reading: Position.self, writing: Velocity.self, where: notFrozen) { _, velocity in
            velocity.dx = 2
            writes += 1
        }
        #expect(writes == moving)
        #expect(storage.get(Velocity.self, for: entities[2])?.dx == 2)
        #expect(storage.get(Velocity.self, for: entities[6])?.dx == 1) // frozen: untouched

        let family = FamilyFilter(requires: ComponentMask(Position.self, Velocity.self), excludes: ComponentMask(Frozen.self))
        #expect(storage.canBecomeMember(entities[2], in: family))
        #expect(!storage.canBecomeMember(entities[6], in: family))
        #expect(!storage.canBecomeMember(entities[1], in: family))
    }
}

private enum Destroy: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entities = storage.makeEntities(5)
        for entity in entities {
            storage.set(Position(x: 1), for: entity)
            storage.set(Label(text: "x"), for: entity)
            storage.set(Frozen(), for: entity)
        }
        let victim = entities[2]
        #expect(storage.destroyEntity(victim))
        #expect(!storage.destroyEntity(victim))
        #expect(!storage.isAlive(victim))
        #expect(storage.entityCount == 4)
        #expect(storage.get(Position.self, for: victim) == nil)
        #expect(!storage.has(Label.self, for: victim))
        #expect(storage.componentIndices(of: victim).isEmpty)

        var visited = 0
        storage.forEach(reading: Position.self, Label.self) { _, _ in visited += 1 }
        #expect(visited == 4)

        // The index is reused and the new entity starts empty.
        let reused = storage.createEntity()
        #expect(reused.index == victim.index)
        #expect(storage.componentIndices(of: reused).isEmpty)
        #expect(storage.get(Position.self, for: reused) == nil)
        for entity in entities where entity != victim {
            #expect(storage.get(Label.self, for: entity) == Label(text: "x"))
        }
    }
}

private enum Iteration: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let count = 3000
        for offset in 0 ..< count {
            let entity = storage.createEntity()
            let value = Double(offset)
            storage.set(Position(x: value), for: entity)
            storage.set(Velocity(dx: 1), for: entity)
            storage.set(Mass(kilograms: 2), for: entity)
            storage.set(Charge(coulombs: 3), for: entity)
            if offset % 10 == 0 {
                storage.set(Spin(turns: 4), for: entity)
            }
            if offset % 100 == 1 {
                storage.set(Label(text: "decoy"), for: entity)
            }
        }
        let positionSum = (0 ..< count).reduce(0.0) { $0 + Double($1) }

        var sum1 = 0.0
        storage.forEach(reading: Position.self) { sum1 += $0.x }
        #expect(sum1 == positionSum)

        var sum2 = 0.0
        storage.forEach(reading: Position.self, Mass.self) { sum2 += $0.x * $1.kilograms }
        #expect(sum2 == positionSum * 2)

        var sum4 = 0.0
        storage.forEach(reading: Position.self, Velocity.self, Mass.self, Charge.self) { sum4 += $0.x + $1.dx + $2.kilograms + $3.coulombs }
        #expect(sum4 == positionSum + Double(count) * 6)

        storage.forEach(reading: Position.self, writing: Velocity.self) { position, velocity in velocity.dx += position.x }
        #expect(storage.get(Velocity.self, for: EntityID(index: 7))?.dx == 8)

        storage.forEach(reading: Mass.self, Charge.self, writing: Position.self) { mass, charge, position in
            position.y = mass.kilograms + charge.coulombs
        }
        #expect(storage.get(Position.self, for: EntityID(index: 11)) == Position(x: 11, y: 5))

        var sparse = 0
        var spinSum = 0.0
        storage.forEach(reading: Spin.self, Position.self) { spin, _ in
            sparse += 1
            spinSum += spin.turns
        }
        #expect(sparse == count / 10)
        #expect(spinSum == Double(count / 10) * 4)

        var packed = 0.0
        var members = 0
        storage.forEach(reading: Position.self, Velocity.self, Mass.self, Charge.self, Spin.self, Frozen.self, where: .none) { _, _, _, _, _, _ in
            members += 1
        }
        #expect(members == 0) // nobody is frozen
        storage.forEach(reading: Position.self, Velocity.self, Mass.self, Charge.self, Spin.self, where: .none) { position, _, mass, _, spin in
            packed += position.x + mass.kilograms + spin.turns
        }
        let spinners = (0 ..< count).filter { $0 % 10 == 0 }
        #expect(packed == spinners.reduce(0.0) { $0 + Double($1) + 6 })
    }
}

private enum Untyped: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let entity = storage.createEntity()
        storage.assign(any: Position(x: 1), to: entity)
        storage.assign(any: Label(text: "a"), to: entity)
        storage.assign(any: Position(x: 2), to: entity) // replace through the untyped path
        #expect(storage.get(Position.self, for: entity) == Position(x: 2))
        #expect(storage.componentIndices(of: entity) == [Position.componentIndex, Label.componentIndex])
        #expect(storage.has(componentIndex: Label.componentIndex, for: entity))
        #expect(storage.anyComponent(componentIndex: Label.componentIndex, for: entity) as? Label == Label(text: "a"))
        #expect(storage.anyComponent(componentIndex: Velocity.componentIndex, for: entity) == nil)
        #expect(storage.remove(componentIndex: Label.componentIndex, from: entity))
        #expect(!storage.remove(componentIndex: Label.componentIndex, from: entity))
        #expect(!storage.has(componentIndex: Label.componentIndex, for: entity))
        #expect(storage.get(Position.self, for: entity) == Position(x: 2))
    }
}

private enum Bulk: StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S) {
        let count = 2500
        for offset in 0 ..< count {
            let entity = storage.createEntity()
            storage.set(Position(x: Double(offset)), for: entity)
            if offset.isMultiple(of: 2) {
                storage.set(Frozen(), for: entity) // spreads entities over two archetypes
            }
        }
        var seen = 0
        storage.withComponents(of: Position.self) { entities, components in
            #expect(entities.count == components.count)
            seen += components.count
            for index in 0 ..< components.count {
                #expect(components[index].x == Double(entities[index]))
                components[index].y = 1
            }
        }
        #expect(seen == count)
        #expect(storage.get(Position.self, for: EntityID(index: 1234))?.y == 1)
        var empty = true
        storage.withComponents(of: Charge.self) { _, _ in empty = false }
        #expect(empty)
    }
}

// MARK: - Structural changes during iteration trap (D4)

private func setDuringIteration<S: NexusStorageProviding>(_: S.Type) {
    let storage = S()
    let entity = storage.createEntity()
    storage.set(Position(), for: entity)
    storage.forEach(reading: Position.self) { _ in
        storage.set(Velocity(), for: entity)
    }
}

private func destroyDuringModify<S: NexusStorageProviding>(_: S.Type) {
    let storage = S()
    let entity = storage.createEntity()
    storage.set(Position(), for: entity)
    _ = storage.modify(Position.self, for: entity) { _ in
        storage.destroyEntity(entity)
    }
}

@Suite struct StructuralChangeTrapTests {
    @Test func sparseSetTrapsOnSetDuringIteration() async {
        await #expect(processExitsWith: .failure) { setDuringIteration(SparseSetStorage.self) }
    }

    @Test func archetypeTrapsOnSetDuringIteration() async {
        await #expect(processExitsWith: .failure) { setDuringIteration(ArchetypeStorage.self) }
    }

    @Test func blockSparseSetTrapsOnSetDuringIteration() async {
        await #expect(processExitsWith: .failure) { setDuringIteration(BlockSparseSetStorage.self) }
    }

    @Test func sparseSetTrapsOnDestroyDuringModify() async {
        await #expect(processExitsWith: .failure) { destroyDuringModify(SparseSetStorage.self) }
    }

    @Test func archetypeTrapsOnDestroyDuringModify() async {
        await #expect(processExitsWith: .failure) { destroyDuringModify(ArchetypeStorage.self) }
    }
}

@Suite struct PagedSparseIndexTests {
    @Test func sparseIndexAllocatesPagesOnDemand() {
        let index = PagedSparseIndex()
        #expect(index.allocatedPageCount == 0)
        #expect(index.slot(of: 5) == -1)
        #expect(index.slot(of: 1_000_000) == -1)
        index.set(5, slot: 0)
        index.set(UInt32(PagedSparseIndex.pageSize * 40), slot: 1)
        #expect(index.allocatedPageCount == 2)
        #expect(index.slot(of: 5) == 0)
        #expect(index.slot(of: UInt32(PagedSparseIndex.pageSize * 40)) == 1)
        index.clear(5)
        #expect(index.slot(of: 5) == -1)
    }
}
