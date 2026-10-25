//
//  ArchetypeStorage.swift
//  S2Storage
//

// Arity-numbered names (c0, b0) mirror the per-arity overloads.
// swiftlint:disable identifier_name function_body_length

/// Archetype storage: entities with the same component set live in one table with a column per component type.
///
/// - Iterating a family visits every matching table and walks its columns linearly: no per-entity lookup,
///   perfectly sequential reads. Cost grows with the number of tables, not entities.
/// - Adding or removing a component moves the entity's whole row to another table (all other components
///   are copied), so churning components is the weak spot. Transitions are cached as edges between tables.
/// - Random access (`get`) is two array reads (location, column) after the mask test.
public final class ArchetypeStorage: NexusStorageProviding {
    @usableFromInline struct Location {
        var table: Int32
        var row: Int32
    }

    @usableFromInline var entities = EntityTable()
    @usableFromInline var locations = ContiguousArray<Location>()
    @usableFromInline var tables = ContiguousArray<ArchetypeTable>()
    var tableIndex: [ComponentMask: Int] = [:]
    @usableFromInline var lockDepth = 0

    public required init() {
        tables.append(ArchetypeTable(mask: ComponentMask(), columns: []))
        tableIndex[ComponentMask()] = 0
    }

    /// The number of distinct component sets seen so far, including the empty one.
    public var tableCount: Int {
        tables.count
    }

    // MARK: Helpers

    @inlinable
    func requireUnlocked() {
        precondition(lockDepth == 0, "structural change while a scoped access or iteration is running")
    }

    func table(for mask: ComponentMask, makeColumns: () -> [(Int, AnyColumn)]) -> Int {
        if let index = tableIndex[mask] {
            return index
        }
        tables.append(ArchetypeTable(mask: mask, columns: makeColumns()))
        tableIndex[mask] = tables.count - 1
        return tables.count - 1
    }

    /// Removes the entity-index bookkeeping of `row` in `table` (columns are handled by the caller).
    func removeRowEntry(_ row: Int, in table: ArchetypeTable) {
        let last = table.entities.count - 1
        if row != last {
            let moved = table.entities[last]
            table.entities[row] = moved
            locations[Int(moved)].row = Int32(row)
        }
        table.entities.removeLast()
    }

    /// Moves the row of `entity` into `target`. Columns that exist in both tables are moved; columns only in
    /// the source are dropped. Columns only in the target must be appended by the caller afterwards.
    func move(_ entity: EntityID, to targetIndex: Int) {
        let location = locations[Int(entity.index)]
        let source = tables[Int(location.table)]
        let target = tables[targetIndex]
        let row = Int(location.row)
        let newRow = target.entities.count
        target.entities.append(entity.index)
        for index in source.columnIndices {
            guard let sourceColumn = source.columns[index] else {
                continue
            }
            if index < target.columns.count, let targetColumn = target.columns[index] {
                targetColumn.moveAppend(from: sourceColumn, row: row)
            } else {
                sourceColumn.swapRemove(row)
            }
        }
        removeRowEntry(row, in: source)
        locations[Int(entity.index)] = Location(table: Int32(targetIndex), row: Int32(newRow))
    }

    func tableAfterAdding<C: Component>(_: C.Type, to sourceIndex: Int) -> Int {
        let source = tables[sourceIndex]
        let cached = source.edge(source.addEdges, C.componentIndex)
        if cached >= 0 {
            return cached
        }
        var mask = source.mask
        mask.insert(C.componentIndex)
        let target = table(for: mask) {
            source.columnIndices.compactMap { index in source.columns[index].map { (index, $0.makeEmpty()) } }
                + [(C.componentIndex, Column<C>())]
        }
        source.setEdge(&source.addEdges, C.componentIndex, to: target)
        return target
    }

    func tableAfterRemoving(_ componentIndex: Int, from sourceIndex: Int) -> Int {
        let source = tables[sourceIndex]
        let cached = source.edge(source.removeEdges, componentIndex)
        if cached >= 0 {
            return cached
        }
        var mask = source.mask
        mask.remove(componentIndex)
        let target = table(for: mask) {
            source.columnIndices.compactMap { index in
                index == componentIndex ? nil : source.columns[index].map { (index, $0.makeEmpty()) }
            }
        }
        source.setEdge(&source.removeEdges, componentIndex, to: target)
        return target
    }

    // MARK: Entities

    public var entityCount: Int {
        entities.liveCount
    }

    public func createEntity() -> EntityID {
        requireUnlocked()
        let entity = entities.create()
        let empty = tables[0]
        let location = Location(table: 0, row: Int32(empty.entities.count))
        empty.entities.append(entity.index)
        if Int(entity.index) < locations.count {
            locations[Int(entity.index)] = location
        } else {
            locations.append(location)
        }
        return entity
    }

    @discardableResult
    public func destroyEntity(_ entity: EntityID) -> Bool {
        requireUnlocked()
        guard entities.isAlive(entity) else {
            return false
        }
        let location = locations[Int(entity.index)]
        let table = tables[Int(location.table)]
        for index in table.columnIndices {
            table.columns[index]?.swapRemove(Int(location.row))
        }
        removeRowEntry(Int(location.row), in: table)
        return entities.destroy(entity)
    }

    public func isAlive(_ entity: EntityID) -> Bool {
        entities.isAlive(entity)
    }

    // MARK: Typed component access

    public func set<C: Component>(_ component: C, for entity: EntityID) {
        requireUnlocked()
        precondition(entities.isAlive(entity), "set on a dead entity")
        precondition(C.componentIndex >= 0 && C.componentIndex < ComponentMask.capacity, "component index out of range")
        let location = locations[Int(entity.index)]
        if let column = tables[Int(location.table)].column(C.self) {
            column.items[Int(location.row)] = component
            return
        }
        let target = tableAfterAdding(C.self, to: Int(location.table))
        move(entity, to: target)
        tables[target].column(C.self).unsafelyUnwrapped.items.append(component)
        entities.insert(C.componentIndex, into: entity)
    }

    public func get<C: Component>(_: C.Type, for entity: EntityID) -> C? {
        guard entities.isAlive(entity) else {
            return nil
        }
        let location = locations[Int(entity.index)]
        return tables[Int(location.table)].column(C.self)?.items[Int(location.row)]
    }

    public func modify<C: Component>(_: C.Type, for entity: EntityID, _ body: (inout C) -> Void) -> Bool {
        guard entities.isAlive(entity) else {
            return false
        }
        let location = locations[Int(entity.index)]
        guard let column = tables[Int(location.table)].column(C.self) else {
            return false
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        body(&column.items[Int(location.row)])
        return true
    }

    @discardableResult
    public func remove<C: Component>(_: C.Type, from entity: EntityID) -> Bool {
        remove(componentIndex: C.componentIndex, from: entity)
    }

    public func has<C: Component>(_: C.Type, for entity: EntityID) -> Bool {
        entities.mask(of: entity).contains(C.componentIndex)
    }

    // MARK: Untyped slow paths

    public func componentIndices(of entity: EntityID) -> [Int] {
        var result: [Int] = []
        entities.mask(of: entity).forEachIndex { result.append($0) }
        return result
    }

    public func has(componentIndex: Int, for entity: EntityID) -> Bool {
        entities.mask(of: entity).contains(componentIndex)
    }

    @discardableResult
    public func remove(componentIndex: Int, from entity: EntityID) -> Bool {
        requireUnlocked()
        guard entities.isAlive(entity), entities.mask(of: entity).contains(componentIndex) else {
            return false
        }
        move(entity, to: tableAfterRemoving(componentIndex, from: Int(locations[Int(entity.index)].table)))
        entities.remove(componentIndex, from: entity)
        return true
    }

    public func anyComponent(componentIndex: Int, for entity: EntityID) -> (any Component)? {
        guard entities.isAlive(entity), entities.mask(of: entity).contains(componentIndex) else {
            return nil
        }
        let location = locations[Int(entity.index)]
        return tables[Int(location.table)].columns[componentIndex]?.anyValue(at: Int(location.row))
    }

    public func assign(any component: any Component, to entity: EntityID) {
        set(component, for: entity)
    }

    // MARK: Families

    public func canBecomeMember(_ entity: EntityID, in filter: FamilyFilter) -> Bool {
        entities.isAlive(entity) && filter.accepts(entities.mask(of: entity))
    }

    @inlinable
    func matching(_ filter: FamilyFilter, requiring required: ComponentMask) -> FamilyFilter {
        FamilyFilter(requires: required, excludes: filter.excludes)
    }

    @inlinable
    public func forEach<R0: Component>(reading _: R0.Type, where filter: FamilyFilter, _ body: (R0) -> Void) {
        var required = filter.requires
        required.insert(R0.componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let b0 = table.column(R0.self).unsafelyUnwrapped.base
            for row in 0 ..< table.entities.count {
                body(b0[row])
            }
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component>(reading _: R0.Type, _: R1.Type, where filter: FamilyFilter, _ body: (R0, R1) -> Void) {
        var required = filter.requires
        required.insert(R0.componentIndex)
        required.insert(R1.componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let b0 = table.column(R0.self).unsafelyUnwrapped.base
            let b1 = table.column(R1.self).unsafelyUnwrapped.base
            for row in 0 ..< table.entities.count {
                body(b0[row], b1[row])
            }
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, R2: Component, R3: Component>(
        reading _: R0.Type, _: R1.Type, _: R2.Type, _: R3.Type,
        where filter: FamilyFilter, _ body: (R0, R1, R2, R3) -> Void
    ) {
        var required = filter.requires
        required.insert(R0.componentIndex)
        required.insert(R1.componentIndex)
        required.insert(R2.componentIndex)
        required.insert(R3.componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let b0 = table.column(R0.self).unsafelyUnwrapped.base
            let b1 = table.column(R1.self).unsafelyUnwrapped.base
            let b2 = table.column(R2.self).unsafelyUnwrapped.base
            let b3 = table.column(R3.self).unsafelyUnwrapped.base
            for row in 0 ..< table.entities.count {
                body(b0[row], b1[row], b2[row], b3[row])
            }
        }
    }

    @inlinable
    public func forEach<R0: Component, W0: Component>(
        reading _: R0.Type, writing _: W0.Type, where filter: FamilyFilter, _ body: (R0, inout W0) -> Void
    ) {
        var required = filter.requires
        required.insert(R0.componentIndex)
        required.insert(W0.componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let b0 = table.column(R0.self).unsafelyUnwrapped.base
            let c0 = table.column(W0.self).unsafelyUnwrapped.base
            for row in 0 ..< table.entities.count {
                body(b0[row], &c0[row])
            }
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, W0: Component>(
        reading _: R0.Type, _: R1.Type, writing _: W0.Type, where filter: FamilyFilter, _ body: (R0, R1, inout W0) -> Void
    ) {
        var required = filter.requires
        required.insert(R0.componentIndex)
        required.insert(R1.componentIndex)
        required.insert(W0.componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let b0 = table.column(R0.self).unsafelyUnwrapped.base
            let b1 = table.column(R1.self).unsafelyUnwrapped.base
            let c0 = table.column(W0.self).unsafelyUnwrapped.base
            for row in 0 ..< table.entities.count {
                body(b0[row], b1[row], &c0[row])
            }
        }
    }

    @inlinable
    public func forEach<each R: Component>(reading _: repeat (each R).Type, where filter: FamilyFilter, _ body: (repeat each R) -> Void) {
        var required = filter.requires
        repeat required.insert((each R).componentIndex)
        let family = matching(filter, requiring: required)
        lockDepth += 1
        defer {
            lockDepth -= 1
        }
        for table in tables where !table.entities.isEmpty && family.accepts(table.mask) {
            let bases = (repeat ColumnCursor((each R).self, in: table))
            for row in 0 ..< table.entities.count {
                body(repeat (each bases).value(row))
            }
        }
    }

    // MARK: Bulk access

    public func withComponents<C: Component>(
        of _: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void
    ) {
        lockDepth += 1
        defer { lockDepth -= 1 }
        for table in tables where !table.entities.isEmpty {
            guard let column = table.column(C.self) else {
                continue
            }
            table.entities.withUnsafeBufferPointer { ids in
                column.items.withUnsafeMutableBufferPointer { components in
                    body(ids, components)
                }
            }
        }
    }
}

/// Hoisted column address of one component type for a parameter-pack iteration over a table.
public struct ColumnCursor<C: Component> {
    @usableFromInline let base: UnsafeMutablePointer<C>

    @inlinable
    init(_: C.Type, in table: ArchetypeTable) {
        base = table.column(C.self).unsafelyUnwrapped.base
    }

    @inlinable
    func value(_ row: Int) -> C {
        base[row]
    }
}
