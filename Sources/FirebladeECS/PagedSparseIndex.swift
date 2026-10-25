//
//  PagedSparseIndex.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Maps an entity index to the dense slot of one component type, or `-1` when the entity has none.
    ///
    /// The index is paged: a page holds `pageSize` slots and is allocated when the first entity in its range
    /// gets the component, so a type that only few entities use costs memory per touched page, not per entity.
    /// Pages are never released before the index itself. A page table pointer plus page pointers keep lookups
    /// free of array bounds checks, exclusivity checks and reference counting.
    ///
    /// Soundness of `@exclusivity(unchecked)`: the table is only mutated by `set` and `clear`, which the owning
    /// storage calls only while no scoped access or iteration runs (`SparseSetStorage.requireUnlocked`),
    /// and a single thread uses a nexus at a time, so no read overlaps a write.
    @usableFromInline
    final class PagedSparseIndex {
        /// log2 of the number of slots per page.
        @usableFromInline static let pageShift = 12
        /// The number of slots per page (4096 slots of 4 bytes: 16 KiB).
        @usableFromInline static let pageSize = 1 << pageShift

        @exclusivity(unchecked)
        @usableFromInline var table: UnsafeMutablePointer<UnsafeMutablePointer<Int32>?>
        @exclusivity(unchecked)
        @usableFromInline var tableCapacity: Int

        @usableFromInline
        init() {
            tableCapacity = 4
            table = .allocate(capacity: tableCapacity)
            table.initialize(repeating: nil, count: tableCapacity)
        }

        deinit {
            for page in 0 ..< tableCapacity {
                table[page]?.deallocate()
            }
            table.deallocate()
        }

        /// The number of allocated pages.
        @usableFromInline var allocatedPageCount: Int {
            (0 ..< tableCapacity).reduce(into: 0) { $0 += table[$1] == nil ? 0 : 1 }
        }

        /// The dense slot for `index`, or `-1`.
        @inlinable
        func slot(of index: UInt32) -> Int {
            let pageNumber = Int(index) >> Self.pageShift
            guard pageNumber < tableCapacity, let page = table[pageNumber] else {
                return -1
            }
            return Int(page[Int(index) & (Self.pageSize - 1)])
        }

        /// Records that `index` lives in dense `slot`.
        @usableFromInline
        func set(_ index: UInt32, slot: Int) {
            let pageNumber = Int(index) >> Self.pageShift
            if pageNumber >= tableCapacity {
                growTable(toFit: pageNumber)
            }
            let page: UnsafeMutablePointer<Int32>
            if let existing = table[pageNumber] {
                page = existing
            } else {
                page = .allocate(capacity: Self.pageSize)
                page.initialize(repeating: -1, count: Self.pageSize)
                table[pageNumber] = page
            }
            page[Int(index) & (Self.pageSize - 1)] = Int32(truncatingIfNeeded: slot)
        }

        /// Forgets `index`.
        @usableFromInline
        func clear(_ index: UInt32) {
            let pageNumber = Int(index) >> Self.pageShift
            if pageNumber < tableCapacity, let page = table[pageNumber] {
                page[Int(index) & (Self.pageSize - 1)] = -1
            }
        }

        private func growTable(toFit pageNumber: Int) {
            var newCapacity = tableCapacity
            while newCapacity <= pageNumber {
                newCapacity *= 2
            }
            let newTable = UnsafeMutablePointer<UnsafeMutablePointer<Int32>?>.allocate(capacity: newCapacity)
            newTable.moveInitialize(from: table, count: tableCapacity)
            (newTable + tableCapacity).initialize(repeating: nil, count: newCapacity - tableCapacity)
            table.deallocate()
            table = newTable
            tableCapacity = newCapacity
        }
    }
}
