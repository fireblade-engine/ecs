//
//  ArchetypeTable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Type-erased base of one column of an ``ArchetypeTable``.
    ///
    /// The untyped methods are the slow paths (row moves between tables, destruction, snapshots, inspection);
    /// hot paths cast to the typed ``Column`` with `unsafeDowncast` after checking `typeID`.
    @usableFromInline
    class AnyColumn {
        /// The component type of this column; guards `unsafeDowncast` against two types sharing an index.
        @usableFromInline final let typeID: ObjectIdentifier
        /// The runtime identifier of the component type.
        @usableFromInline final let identifier: ComponentIdentifier

        @usableFromInline
        init(typeID: ObjectIdentifier, identifier: ComponentIdentifier) {
            self.typeID = typeID
            self.identifier = identifier
        }

        // swiftlint:disable unavailable_function
        /// A column of the same component type without rows.
        @usableFromInline
        func makeEmpty() -> AnyColumn {
            fatalError("abstract")
        }

        /// Removes `row` by swapping the last row into its place.
        ///
        /// - Returns: The removed value, or `nil` if releasing it cannot run code (plain data). The caller releases it
        ///   last, after its own bookkeeping is consistent, because releasing can run a `deinit` that re-enters the nexus.
        @usableFromInline
        func swapRemove(_: Int) -> (any Component)? {
            fatalError("abstract")
        }

        /// Removes `row` of the column, which holds a value that was moved out, without releasing anything.
        @usableFromInline
        func swapRemoveMovedOut(_: Int) {
            fatalError("abstract")
        }

        /// Moves `row` of `other` (same type) to the end of this column and fills the hole with `other`'s last row.
        @usableFromInline
        func moveAppend(from _: AnyColumn, row _: Int) {
            fatalError("abstract")
        }

        /// The component of a row.
        @usableFromInline
        func anyValue(at _: Int) -> any Component {
            fatalError("abstract")
        }
        // swiftlint:enable unavailable_function
    }

    /// One component type's values of an ``ArchetypeTable``: row `i` belongs to `ArchetypeTable.entities[i]`.
    ///
    /// The values live in a hand-managed buffer this class owns, so moving a row between tables is one `moveInitialize`
    /// per column and a pointer to row 0 never comes from a `withUnsafe…` scope. Elements are initialized and
    /// deinitialized by hand; `deinit` releases the live ones. Removal swaps the last row into the hole.
    ///
    /// Soundness of `@exclusivity(unchecked)`: `base`, `count` and `capacity` change only in structural changes, which
    /// `ArchetypeStorage` blocks while a scoped access or iteration runs, and a single thread uses a nexus at a time.
    @usableFromInline
    final class Column<C: Component>: AnyColumn {
        /// Address of row 0; dangling (never dereferenced) while `capacity` is 0.
        @exclusivity(unchecked)
        @usableFromInline var base: UnsafeMutablePointer<C>
        @exclusivity(unchecked)
        @usableFromInline var count = 0
        @exclusivity(unchecked)
        @usableFromInline var capacity = 0

        @usableFromInline
        init() {
            base = UnsafeMutablePointer<C>(bitPattern: MemoryLayout<C>.alignment).unsafelyUnwrapped
            super.init(typeID: ObjectIdentifier(C.self), identifier: C.identifier)
        }

        deinit {
            base.deinitialize(count: count)
            if capacity > 0 {
                base.deallocate()
            }
        }

        @inlinable
        subscript(row: Int) -> C {
            unsafeAddress { UnsafePointer(base + row) }
            unsafeMutableAddress { base + row }
        }

        @inlinable
        func append(_ value: C) {
            if count == capacity {
                grow()
            }
            (base + count).initialize(to: value)
            count += 1
        }

        @usableFromInline
        func grow() {
            let newCapacity = max(8, capacity * 2)
            let newBase = UnsafeMutablePointer<C>.allocate(capacity: newCapacity)
            newBase.moveInitialize(from: base, count: count)
            if capacity > 0 {
                base.deallocate()
            }
            base = newBase
            capacity = newCapacity
        }

        /// Fills the hole at `row` (deinitialized or moved out already) with the last row.
        @inlinable
        func fillHole(_ row: Int) {
            let last = count - 1
            if row != last {
                (base + row).moveInitialize(from: base + last, count: 1)
            }
            count = last
        }

        @usableFromInline
        override func makeEmpty() -> AnyColumn {
            Column<C>()
        }

        @usableFromInline
        override func swapRemove(_ row: Int) -> (any Component)? {
            if _isPOD(C.self) {
                fillHole(row)
                return nil
            }
            let removed = (base + row).move()
            fillHole(row)
            return removed
        }

        @usableFromInline
        override func swapRemoveMovedOut(_ row: Int) {
            fillHole(row)
        }

        @usableFromInline
        override func moveAppend(from other: AnyColumn, row: Int) {
            let source = unsafeDowncast(other, to: Column<C>.self)
            if count == capacity {
                grow()
            }
            (base + count).moveInitialize(from: source.base + row, count: 1)
            count += 1
            source.fillHole(row)
        }

        @usableFromInline
        override func anyValue(at row: Int) -> any Component {
            self[row]
        }
    }

    /// All entities that share one component set: a column per component type plus the entity index of every row.
    ///
    /// Tables are created on demand and then live as long as the storage (see ``ArchetypeStorage``). A table keeps cached
    /// transitions to the tables after adding or removing one component type (edges, like the table graph of flecs),
    /// so a structural change finds its target table without hashing the component set.
    @usableFromInline
    final class ArchetypeTable {
        /// The component set of every entity in this table.
        @usableFromInline let mask: ComponentMask
        /// The entity index of every row.
        @exclusivity(unchecked)
        @usableFromInline var entities = ContiguousArray<UInt32>()
        /// Indexed by component index; `nil` for component types that are not in `mask`.
        @exclusivity(unchecked)
        @usableFromInline var columns: ContiguousArray<AnyColumn?>
        /// The same columns without reference counting, for loops. `columns` keeps them alive.
        @exclusivity(unchecked)
        @usableFromInline var unmanagedColumns: ContiguousArray<Unmanaged<AnyColumn>?>
        /// The component indices in `mask`, ascending.
        @usableFromInline let columnIndices: [Int]
        /// Cached transitions: `addEdges[c]` is the table after adding component type `c`, `-1` while unknown.
        @exclusivity(unchecked)
        @usableFromInline var addEdges = ContiguousArray<Int32>()
        /// Cached transitions: `removeEdges[c]` is the table after removing component type `c`, `-1` while unknown.
        @exclusivity(unchecked)
        @usableFromInline var removeEdges = ContiguousArray<Int32>()

        @usableFromInline
        init(mask: ComponentMask, columns: [(index: Int, column: AnyColumn)]) {
            self.mask = mask
            var owned = ContiguousArray<AnyColumn?>()
            var unmanaged = ContiguousArray<Unmanaged<AnyColumn>?>()
            for (index, column) in columns {
                while owned.count <= index {
                    owned.append(nil)
                    unmanaged.append(nil)
                }
                owned[index] = column
                unmanaged[index] = Unmanaged.passUnretained(column)
            }
            self.columns = owned
            unmanagedColumns = unmanaged
            columnIndices = columns.map(\.index)
        }

        /// The number of entities in this table.
        @inlinable var rowCount: Int {
            entities.count
        }

        /// The column of a component type, or `nil` if the table has none.
        @inlinable
        func column<C: Component>(_: C.Type, at index: Int) -> Column<C>? {
            guard index >= 0, index < columns.count, let column = columns[index] else {
                return nil
            }
            precondition(column.typeID == ObjectIdentifier(C.self), "component index \(index) is used by two component types")
            return unsafeDowncast(column, to: Column<C>.self)
        }

        /// The address of row 0 of a column, without retaining the column. The table must have the column.
        @inlinable
        func base<C: Component>(_: C.Type, at index: Int) -> UnsafeMutablePointer<C> {
            unmanagedColumns[index].unsafelyUnwrapped._withUnsafeGuaranteedRef { column in
                precondition(column.typeID == ObjectIdentifier(C.self), "component index \(index) is used by two component types")
                return unsafeDowncast(column, to: Column<C>.self).base
            }
        }

        @usableFromInline
        static func edge(_ edges: ContiguousArray<Int32>, _ componentIndex: Int) -> Int {
            componentIndex < edges.count ? Int(edges[componentIndex]) : -1
        }

        @usableFromInline
        static func setEdge(_ edges: inout ContiguousArray<Int32>, _ componentIndex: Int, to table: Int) {
            while edges.count <= componentIndex {
                edges.append(-1)
            }
            edges[componentIndex] = Int32(table)
        }
    }

    /// The tables matching one family filter, as unretained references (``ArchetypeStorage/tables`` owns them).
    ///
    /// The list is extended by the tables created since the last query and never rebuilt, because tables are not
    /// removed while the storage lives.
    @usableFromInline
    final class TableQuery {
        @usableFromInline var tables = ContiguousArray<Unmanaged<ArchetypeTable>>()
        @usableFromInline var scanned = 0

        @usableFromInline
        init() {}
    }
}
