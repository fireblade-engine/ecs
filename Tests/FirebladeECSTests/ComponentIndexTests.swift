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

    @Test func indicesAreProcessWide() {
        let first = Nexus()
        let second = Nexus()
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
