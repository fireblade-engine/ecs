//
//  ComponentIndexTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

import Testing
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
        // other suites may register types concurrently, so only a lower bound holds for the delta
        #expect(after - before >= types.count)
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
