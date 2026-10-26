//
//  ArchetypeStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Where an entity lives: its table and the row in it.
    @usableFromInline
    struct EntityLocation {
        @usableFromInline var table: UInt32
        @usableFromInline var row: UInt32

        @usableFromInline
        init(table: UInt32, row: UInt32) {
            self.table = table
            self.row = row
        }
    }

    /// Archetype storage: entities with the same component set live in one table with a column per component type.
    ///
    /// This is the storage design of flecs ("Archetypes", <https://www.flecs.dev/flecs/md_docs_2Queries.html>): one table per
    /// component set, columns as arrays, an entity index that maps every entity to its table and row, and cached edges
    /// between tables for adding and removing one component type.
    ///
    /// - Iterating a family visits the tables that match it and walks their columns linearly: no per-entity lookup.
    ///   The cost grows with the number of matching tables, not with the number of entities.
    /// - Adding or removing a component moves the whole row of the entity into another table (swap-remove in the old
    ///   table keeps the rows dense and updates the entity index of the entity that moved), so a component set that
    ///   changes every frame is the weak spot. The target table is found through a cached edge.
    /// - Random access (`get`) is the entity index, a column lookup and an array read.
    /// - Tables are created when a component set is seen first and are never removed while the storage lives: a table
    ///   that became empty keeps its columns (their capacity is reused when entities of that set return) and stays in
    ///   the cached query lists, where it costs one skipped table per pass. ``removeAll()`` drops all tables.
    ///
    /// The storage traps on misuse like ``SparseSetStorage``: a structural change while a scoped access or iteration
    /// runs, a second write access to a type that is being written, a read of a type that is being written, and two
    /// component types that share an index.
    ///
    /// Soundness of `@exclusivity(unchecked)` and of the unretained table references: the stored properties change only in
    /// structural changes and in the `beginWrite`/`endWrite`/`lockDepth` bookkeeping. Structural changes are blocked while
    /// a scoped access runs (`requireUnlocked`), tables and columns are never removed while a scope is open, and a single
    /// thread uses a nexus at a time, so no access overlaps a change.
    @usableFromInline
    final class ArchetypeStorage {
        /// Liveness and component set of every entity slot.
        @exclusivity(unchecked)
        @usableFromInline var entities = EntityTable()
        /// The table and row of every entity slot, indexed by `EntityIdentifier.index`.
        @exclusivity(unchecked)
        @usableFromInline var locations = ContiguousArray<EntityLocation>()
        /// Table 0 is the table of entities without components.
        @exclusivity(unchecked)
        @usableFromInline var tables = ContiguousArray<ArchetypeTable>()
        @usableFromInline var tableIndexByMask: [ComponentMask: Int] = [:]
        /// An empty column of every known component type, indexed by component index. Seeds the columns of new tables.
        @exclusivity(unchecked)
        @usableFromInline var prototypes = ContiguousArray<AnyColumn?>()
        /// The index of every known component type, by its runtime identifier.
        @exclusivity(unchecked)
        @usableFromInline var indexByIdentifier: [ComponentIdentifier: Int] = [:]
        /// The tables that match each family filter, extended lazily as new tables appear.
        @usableFromInline var queryCache: [FamilyFilter: TableQuery] = [:]
        /// Greater than zero while a scoped access runs; structural changes trap then.
        @exclusivity(unchecked)
        @usableFromInline var lockDepth = 0
        /// Component types with a running write access (`modify`, writing iteration, `withComponents`).
        @exclusivity(unchecked)
        @usableFromInline var activeWrites = ComponentMask()
        /// Component types with a running read span. Writes to them trap.
        @exclusivity(unchecked)
        @usableFromInline var activeReads = ComponentMask()

        @usableFromInline
        init() {
            makeEmptyTable()
        }

        private func makeEmptyTable() {
            tables.append(ArchetypeTable(mask: ComponentMask(), columns: []))
            tableIndexByMask[ComponentMask()] = 0
        }

        /// The number of tables, including the one of entities without components.
        @usableFromInline var tableCount: Int {
            tables.count
        }

        // MARK: Helpers

        @inlinable
        func beginWrite(_ componentIndex: Int) {
            precondition(!activeWrites.contains(componentIndex), "nested write access to component \(componentIndex)")
            precondition(!activeReads.contains(componentIndex), "write access to component \(componentIndex) during a read span of it")
            activeWrites.insert(componentIndex)
        }

        @inlinable
        func endWrite(_ componentIndex: Int) {
            activeWrites.remove(componentIndex)
        }

        @inlinable
        func requireReadable(_ componentIndex: Int) {
            precondition(!activeWrites.contains(componentIndex), "read of component \(componentIndex) during a write access to it")
        }

        @inlinable
        func requireUnlocked() {
            precondition(lockDepth == 0, "structural change while a scoped access is running")
        }

        /// Records the component type, so that tables can be seeded with a column for it.
        @usableFromInline
        func register<C: Component>(_: C.Type, at index: Int) {
            if index >= 0, index < prototypes.count, let known = prototypes[index] {
                precondition(known.typeID == ObjectIdentifier(C.self), "component index \(index) is used by two component types")
                return
            }
            precondition(index >= 0 && index < ComponentIndexRegistry.indexLimit, "component index \(index) is out of range")
            // Components are value types: a class would alias its row and bypass change tracking. The macro
            // rejects classes at compile time, a hand-written conformance is only caught here, in debug builds.
            assert(!(C.self is AnyClass), "component type \(C.self) is a class; components must be structs or enums")
            while prototypes.count <= index {
                prototypes.append(nil)
            }
            let column = Column<C>()
            prototypes[index] = column
            indexByIdentifier[column.identifier] = index
        }

        @inlinable
        func column<C: Component>(_: C.Type, at index: Int, in location: EntityLocation) -> Column<C>? {
            tables[Int(location.table)].column(C.self, at: index)
        }

        // MARK: Tables

        @usableFromInline
        func table(for mask: ComponentMask, makeColumns: () -> [(index: Int, column: AnyColumn)]) -> Int {
            if let index = tableIndexByMask[mask] {
                return index
            }
            tables.append(ArchetypeTable(mask: mask, columns: makeColumns()))
            tableIndexByMask[mask] = tables.count - 1
            return tables.count - 1
        }

        /// The table after adding component type `C` to entities of table `sourceIndex`, through the cached edge.
        @usableFromInline
        func tableAfterAdding<C: Component>(_: C.Type, at componentIndex: Int, to sourceIndex: Int) -> Int {
            let source = tables[sourceIndex]
            let cached = ArchetypeTable.edge(source.addEdges, componentIndex)
            if cached >= 0 {
                return cached
            }
            var mask = source.mask
            mask.insert(componentIndex)
            let target = table(for: mask) {
                var columns = source.columnIndices.map { (index: $0, column: source.columns[$0].unsafelyUnwrapped.makeEmpty()) }
                columns.append((componentIndex, Column<C>()))
                return columns
            }
            ArchetypeTable.setEdge(&source.addEdges, componentIndex, to: target)
            return target
        }

        /// The table after removing component type `componentIndex` from entities of table `sourceIndex`, through the cached edge.
        @usableFromInline
        func tableAfterRemoving(_ componentIndex: Int, from sourceIndex: Int) -> Int {
            let source = tables[sourceIndex]
            let cached = ArchetypeTable.edge(source.removeEdges, componentIndex)
            if cached >= 0 {
                return cached
            }
            var mask = source.mask
            mask.remove(componentIndex)
            let target = table(for: mask) {
                source.columnIndices.filter { $0 != componentIndex }.map { (index: $0, column: source.columns[$0].unsafelyUnwrapped.makeEmpty()) }
            }
            ArchetypeTable.setEdge(&source.removeEdges, componentIndex, to: target)
            return target
        }

        /// Removes the entity-index bookkeeping of `row` in `table`; the caller handled the columns.
        @usableFromInline
        func removeRowEntry(_ row: Int, in table: ArchetypeTable) {
            let last = table.entities.count - 1
            if row != last {
                let moved = table.entities[last]
                table.entities[row] = moved
                locations[Int(moved)].row = UInt32(row)
            }
            table.entities.removeLast()
        }

        /// Moves the row of an entity into another table.
        ///
        /// Columns both tables have are moved. A column only the source has is dropped: its value is returned, to be
        /// released by the caller once its own bookkeeping is consistent (at most one column is dropped, a single
        /// component type is removed at a time). `movedOut` names a column whose value was moved out of its row already
        /// and is not released. Columns only the target has must be appended by the caller afterwards.
        @usableFromInline
        func move(_ entityIndex: UInt32, to targetIndex: Int, movedOut: Int = -1) -> (any Component)? {
            let location = locations[Int(entityIndex)]
            let source = tables[Int(location.table)]
            let target = tables[targetIndex]
            let row = Int(location.row)
            let newRow = target.entities.count
            target.entities.append(entityIndex)
            var dropped: (any Component)?
            for index in source.columnIndices {
                let sourceColumn = source.columns[index].unsafelyUnwrapped
                if index < target.columns.count, let targetColumn = target.columns[index] {
                    targetColumn.moveAppend(from: sourceColumn, row: row)
                } else if index == movedOut {
                    sourceColumn.swapRemoveMovedOut(row)
                } else {
                    dropped = sourceColumn.swapRemove(row)
                }
            }
            removeRowEntry(row, in: source)
            locations[Int(entityIndex)] = EntityLocation(table: UInt32(targetIndex), row: UInt32(newRow))
            return dropped
        }

        /// The tables whose component set matches `filter`, cached per filter. Only tables created since the last
        /// call for this filter are tested again.
        @usableFromInline
        func matchingTables(_ filter: FamilyFilter) -> TableQuery {
            let query: TableQuery
            if let cached = queryCache[filter] {
                query = cached
            } else {
                query = TableQuery()
                queryCache[filter] = query
            }
            while query.scanned < tables.count {
                let table = tables[query.scanned]
                if filter.accepts(table.mask) {
                    query.tables.append(Unmanaged.passUnretained(table))
                }
                query.scanned += 1
            }
            return query
        }

        // MARK: Entities

        @usableFromInline var entityCount: Int {
            entities.liveCount
        }

        @usableFromInline
        func insertEntity(_ entityId: EntityIdentifier) {
            requireUnlocked()
            entities.insert(entityId)
            let index = Int(entityId.index)
            while locations.count <= index {
                locations.append(EntityLocation(table: 0, row: 0))
            }
            let empty = tables[0]
            locations[index] = EntityLocation(table: 0, row: UInt32(empty.entities.count))
            empty.entities.append(entityId.index)
        }

        /// Removes all components of the entity and frees its slot.
        ///
        /// The removed components are released last, after the slot is free, so a `deinit` that re-enters sees consistent state.
        @usableFromInline
        @discardableResult
        func destroyEntity(_ entityId: EntityIdentifier) -> Bool {
            requireUnlocked()
            guard entities.isAlive(entityId) else {
                return false
            }
            let location = locations[Int(entityId.index)]
            let table = tables[Int(location.table)]
            var removed: [any Component] = []
            for index in table.columnIndices {
                if let component = table.columns[index].unsafelyUnwrapped.swapRemove(Int(location.row)) {
                    removed.append(component)
                }
            }
            removeRowEntry(Int(location.row), in: table)
            let destroyed = entities.remove(entityId)
            withExtendedLifetime(removed) {}
            return destroyed
        }

        @inlinable
        func isAlive(_ entityId: EntityIdentifier) -> Bool {
            entities.isAlive(entityId)
        }

        /// Removes all entities and components, and forgets all component types and tables.
        @usableFromInline
        func removeAll() {
            requireUnlocked()
            // Components are released last, so a `deinit` that re-enters sees the emptied storage.
            let released = (tables, prototypes)
            entities = EntityTable()
            locations = []
            tables = []
            tableIndexByMask = [:]
            prototypes = []
            indexByIdentifier.removeAll()
            queryCache.removeAll()
            makeEmptyTable()
            withExtendedLifetime(released) {}
        }
    }
}
