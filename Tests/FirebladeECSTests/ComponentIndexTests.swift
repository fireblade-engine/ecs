//
//  ComponentIndexTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

import Testing
#if !os(WASI)
import Foundation
#endif
@testable import FirebladeECS

private struct IndexA: Component, Sendable {}
private struct IndexB: Component, Sendable {}
private struct IndexC: Component, Sendable {}
private struct ConcurrentlyIndexed: Component, Sendable {}

@Suite struct ComponentIndexTests {
    @Test func plainConformancesGetStableIndices() {
        let a = IndexA.componentIndex
        #expect(IndexA.componentIndex == a)
        #expect(a >= 0)
    }

    @Test func indicesAreDistinctAndDense() {
        let indices = [IndexA.componentIndex, IndexB.componentIndex, IndexC.componentIndex]
        #expect(Set(indices).count == 3)
        // dense: an index is always smaller than the number of types that have one
        #expect(indices.allSatisfy { $0 >= 0 && $0 < Nexus.ComponentIndexRegistry.shared.count })
    }

    @Test(arguments: Nexus.StorageKind.allCases) func indicesAreProcessWide(_ storage: Nexus.StorageKind) {
        let first = Nexus(storage: storage)
        let second = Nexus(storage: storage)
        first.createEntity().set(IndexA())
        second.createEntity().set(IndexB())
        second.createEntity().set(IndexA())
        #expect(first.family(requires: IndexA.self).count == 1)
        #expect(second.family(requires: IndexA.self).count == 1)
        #expect(second.family(requires: IndexB.self).count == 1)
    }

    @Test func concurrentFirstUseAssignsOneIndex() async {
        let indices = await withTaskGroup(of: Int.self) { group in
            for _ in 0 ..< 16 {
                group.addTask { ConcurrentlyIndexed.componentIndex }
            }
            return await group.reduce(into: Set<Int>()) { $0.insert($1) }
        }
        #expect(indices.count == 1)
        #expect(indices.first == ConcurrentlyIndexed.componentIndex)
    }
}

private struct Wrapped<T>: Component, Sendable {}
private enum Tag0 {}
private enum Tag1 {}
private enum Tag2 {}
private enum Tag3 {}
private enum Tag4 {}
private enum Tag5 {}
private enum Tag6 {}
private enum Tag7 {}

/// Many distinct types from generic specializations: `Wrapped<Tag>`, `Wrapped<Wrapped<Tag>>`, ...
private func manyTypes() -> [any Component.Type] {
    var types: [any Component.Type] = []
    func add<T>(_: T.Type) {
        types.append(Wrapped<T>.self)
        types.append(Wrapped<Wrapped<T>>.self)
        types.append(Wrapped<Wrapped<Wrapped<T>>>.self)
        types.append(Wrapped<[T]>.self)
        types.append(Wrapped<T?>.self)
        types.append(Wrapped<(T, T)>.self)
        types.append(Wrapped<[[T]]>.self)
        types.append(Wrapped<[T]?>.self)
    }
    add(Tag0.self); add(Tag1.self); add(Tag2.self); add(Tag3.self)
    add(Tag4.self); add(Tag5.self); add(Tag6.self); add(Tag7.self)
    add(Int.self); add(String.self); add(Double.self); add(Bool.self)
    add(UInt8.self); add(Int16.self); add(Float.self); add(Character.self)
    return types
}

@Suite struct ComponentIndexConcurrencyTests {
    @Test func manyThreadsRegisterOverlappingSetsAndAgree() async {
        let types = manyTypes()
        let before = Nexus.ComponentIndexRegistry.shared.count
        let results = await withTaskGroup(of: [Int].self) { group in
            for thread in 0 ..< 16 {
                group.addTask {
                    // each thread walks the set from a different offset, several times, so first uses overlap
                    var seen = [Int](repeating: -1, count: types.count)
                    for round in 0 ..< 3 {
                        for step in 0 ..< types.count {
                            let i = (step + thread * 7) % types.count
                            let index = Nexus.ComponentIndexRegistry.shared.index(of: types[i])
                            if seen[i] >= 0 { precondition(seen[i] == index, "index changed (round \(round))") }
                            seen[i] = index
                        }
                    }
                    return seen
                }
            }
            return await group.reduce(into: [[Int]]()) { $0.append($1) }
        }
        #expect(results.count == 16)
        #expect(results.allSatisfy { $0 == results[0] })
        let indices = results[0]
        #expect(Set(indices).count == types.count)
        let after = Nexus.ComponentIndexRegistry.shared.count
        // other suites may register the same or other types concurrently, so only the total is bounded
        #expect(after >= types.count)
        #expect(after >= before)
        // dense: every index lies below the number of registered types
        #expect(indices.allSatisfy { $0 >= 0 && $0 < after })
        // stable afterwards, through the lock-free path
        for (type, index) in zip(types, indices) {
            #expect(type.componentIndex == index)
        }
    }

    @Test func firstUseOrderIsDense() {
        struct First: Component {}
        struct Second: Component {}
        struct Third: Component {}
        let first = First.componentIndex
        // other suites may register types in between, so indices increase but need not be adjacent
        let second = Second.componentIndex
        let third = Third.componentIndex
        #expect(first < second && second < third)
        #expect(third < Nexus.ComponentIndexRegistry.shared.count)
        #expect(First.componentIndex == first)
    }
}

private typealias Registry = Nexus.ComponentIndexRegistry

@Suite struct ComponentIndexTableTests {
    /// Fresh keys (non-zero, distinct) whose home slot in a table of this capacity is `slot`.
    private func keys(homing slot: Int, in table: UnsafeMutablePointer<UInt>, count: Int, after start: UInt = 1) -> [UInt] {
        var found: [UInt] = []
        var key = start
        while found.count < count {
            if Registry.homeSlot(key, in: table) == slot { found.append(key) }
            key += 1
        }
        return found
    }

    @Test func collisionsProbeLinearlyAndWrapAround() {
        let table = Registry.makeTable(capacity: 16)
        defer { table.deallocate() }
        let last = 15
        let colliding = keys(homing: last, in: table, count: 4)
        for (offset, key) in colliding.enumerated() {
            Registry.insert(key, 100 + offset, into: table, publish: true)
        }
        // first key sits in its home slot, the others wrapped to slots 0, 1, 2
        #expect(Registry.slotEntry(table, last)[0] == colliding[0])
        for offset in 1 ..< 4 {
            #expect(Registry.slotEntry(table, offset - 1)[0] == colliding[offset])
        }
        for (offset, key) in colliding.enumerated() {
            #expect(Registry.lookup(key, in: table) == 100 + offset)
        }
        // a key probing through the cluster ends at the first empty slot
        let absent = keys(homing: last, in: table, count: 1, after: colliding[3] + 1)[0]
        #expect(Registry.lookup(absent, in: table) == nil)
        #expect(Registry.lookup(keys(homing: 7, in: table, count: 1)[0], in: table) == nil)
    }

    @Test func growthKeepsEntriesAndLeavesTheOldTableReadable() {
        let old = Registry.makeTable(capacity: 16)
        defer { old.deallocate() }
        let all = Array(1 ... 8).map { UInt($0) * 0x1000 + 8 }
        for (index, key) in all.enumerated() {
            Registry.insert(key, index, into: old, publish: true)
        }
        let grown = Registry.makeTable(capacity: 32, copying: old)
        defer { grown.deallocate() }
        let late: UInt = 0xABCD0
        Registry.insert(late, 8, into: grown, publish: true)
        for (index, key) in all.enumerated() {
            #expect(Registry.lookup(key, in: grown) == index)
            // a reader still holding the old table keeps seeing its entries
            #expect(Registry.lookup(key, in: old) == index)
        }
        #expect(Registry.lookup(late, in: grown) == 8)
        // the stale reader misses the late key, which is what sends it to the locked path
        #expect(Registry.lookup(late, in: old) == nil)
    }

    @Test func missFallsBackToTheLockedPathAndIsIdempotent() {
        let registry = Registry.shared
        let key = UInt(bitPattern: ObjectIdentifier(Wrapped<Tag0>.self)) &+ 1 // never a real metatype address
        let table = UnsafeMutablePointer<UInt>(bitPattern: registry.current.pointee).unsafelyUnwrapped
        #expect(Registry.lookup(key, in: table) == nil)
        let index = registry.register(key)
        #expect(registry.register(key) == index)
        let after = UnsafeMutablePointer<UInt>(bitPattern: registry.current.pointee).unsafelyUnwrapped
        #expect(Registry.lookup(key, in: after) == index)
    }
}

#if !os(WASI) // WASI has no threads, Thread and DispatchGroup are unavailable

private final class StartGate: @unchecked Sendable {
    private var arrived = 0
    private let total: Int
    init(_ total: Int) { self.total = total }
    private let mutex = NSLock()
    func wait() {
        mutex.lock(); arrived += 1; mutex.unlock()
        while true {
            mutex.lock(); let done = arrived >= total; mutex.unlock()
            if done { return }
            sched_yield()
        }
    }
}

private struct Fresh<T, U>: Component, Sendable {}

@Suite struct ComponentIndexThreadTests {
    @Test func readersAndWritersOnRealThreadsAgree() {
        let readers = 8, writers = 8
        let gate = StartGate(readers + writers)
        let group = DispatchGroup()
        let results = ResultBox()
        // Each writer registers its own fresh specializations (forcing table growth) plus a shared set.
        let shared = manyTypes()
        for writer in 0 ..< writers {
            group.enter()
            let thread = Thread {
                gate.wait()
                var seen: [Int] = []
                for i in 0 ..< 64 {
                    seen.append(Registry.shared.index(of: Fresh<Wrapped<Tag0>, Wrapped<Tag1>>.self))
                    seen.append(Registry.shared.index(of: shared[(i + writer * 5) % shared.count]))
                    _ = Registry.shared.index(of: freshType(i &+ writer))
                }
                results.append(seen)
                group.leave()
            }
            thread.start()
        }
        for _ in 0 ..< readers {
            group.enter()
            let thread = Thread {
                gate.wait()
                var seen: [Int] = []
                for _ in 0 ..< 200 {
                    for type in shared { seen.append(Registry.shared.index(of: type)) }
                }
                results.append(seen)
                group.leave()
            }
            thread.start()
        }
        group.wait()
        // every observer agrees per type: the shared types keep one index throughout
        let expected = shared.map { Registry.shared.index(of: $0) }
        #expect(Set(expected).count == expected.count)
        for seen in results.value where seen.count == 200 * shared.count {
            for (position, index) in seen.enumerated() {
                #expect(index == expected[position % shared.count])
            }
        }
        #expect(Registry.shared.index(of: Fresh<Wrapped<Tag0>, Wrapped<Tag1>>.self) == Fresh<Wrapped<Tag0>, Wrapped<Tag1>>.componentIndex)
    }
}

private final class ResultBox: @unchecked Sendable {
    private let mutex = NSLock()
    private var stored: [[Int]] = []
    func append(_ value: [Int]) { mutex.lock(); stored.append(value); mutex.unlock() }
    var value: [[Int]] { mutex.lock(); defer { mutex.unlock() }; return stored }
}

/// A few dozen distinct fresh types selected by number.
private func freshType(_ n: Int) -> any Component.Type {
    switch n % 8 {
    case 0: Fresh<Tag0, Tag1>.self
    case 1: Fresh<Tag1, Tag2>.self
    case 2: Fresh<Tag2, Tag3>.self
    case 3: Fresh<Tag3, Tag4>.self
    case 4: Fresh<Tag4, Tag5>.self
    case 5: Fresh<Tag5, Tag6>.self
    case 6: Fresh<Tag6, Tag7>.self
    default: Fresh<Tag7, Tag0>.self
    }
}
#endif
