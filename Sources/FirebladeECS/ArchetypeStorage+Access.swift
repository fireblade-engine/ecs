//
//  ArchetypeStorage+Access.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus.ArchetypeStorage {
    /// Gives `body` write access to the component of an entity.
    /// - Returns: `false` if the entity has no such component.
    @inlinable
    func modify<C: Component>(_: C.Type, for entityId: EntityIdentifier, _ body: (inout C) throws -> Void) rethrows -> Bool {
        let componentIndex = C.componentIndex
        guard entities.isAlive(entityId) else {
            return false
        }
        let location = locations[Int(entityId.index)]
        guard let column = column(C.self, at: componentIndex, in: location) else {
            return false
        }
        beginWrite(componentIndex)
        lockDepth += 1
        defer {
            lockDepth -= 1
            endWrite(componentIndex)
        }
        try body(&column[Int(location.row)])
        return true
    }

    /// Starts a write access to the component of an entity that spans several statements, for `_modify` accessors.
    ///
    /// The type is write locked and structural changes trap until ``endAccess(_:)``.
    /// - Returns: The address of the component in its column, or `nil` if the entity has no such component.
    @inlinable
    func beginAccess<C: Component>(_: C.Type, for entityId: EntityIdentifier) -> UnsafeMutablePointer<C>? {
        let componentIndex = C.componentIndex
        guard entities.isAlive(entityId) else {
            return nil
        }
        let location = locations[Int(entityId.index)]
        guard let column = column(C.self, at: componentIndex, in: location) else {
            return nil
        }
        beginWrite(componentIndex)
        lockDepth += 1
        return column.base + Int(location.row)
    }

    /// Ends the write access started by ``beginAccess(_:for:)``.
    @inlinable
    func endAccess(_ componentIndex: Int) {
        lockDepth -= 1
        endWrite(componentIndex)
    }

    /// Removes a component whose value was moved out of its row and not put back, without releasing it.
    @inlinable
    func discardMovedOut<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        requireUnlocked()
        let componentIndex = C.componentIndex
        guard entities.isAlive(entityId), has(componentIndex: componentIndex, for: entityId) else {
            return
        }
        removeMovedOut(componentIndex, from: entityId)
    }

    @usableFromInline
    func removeMovedOut(_ componentIndex: Int, from entityId: EntityIdentifier) {
        let target = tableAfterRemoving(componentIndex, from: Int(locations[Int(entityId.index)].table))
        _ = move(entityId.index, to: target, movedOut: componentIndex)
        entities.remove(componentIndex, from: entityId)
    }

    /// Starts a read span of the type: it must not be written, and writing it traps until ``endRead(_:wasReading:)``.
    /// - Returns: Whether the type was in a read span already (spans nest); hand it to ``endRead(_:wasReading:)``.
    @inlinable
    func beginRead(_ componentIndex: Int) -> Bool {
        requireReadable(componentIndex)
        let wasReading = activeReads.contains(componentIndex)
        activeReads.insert(componentIndex)
        return wasReading
    }

    @inlinable
    func endRead(_ componentIndex: Int, wasReading: Bool) {
        if !wasReading {
            activeReads.remove(componentIndex)
        }
    }

    /// Gives `body` the entity indices and component values of the type with write access, one call per table that holds rows of it.
    ///
    /// An archetype keeps a component type in one column per table, so the values are not one contiguous buffer: `body` is
    /// called once for every table that has the type and at least one row. The two buffers of a call have the same length,
    /// and element `i` of both belong to the same entity.
    @inlinable
    func withComponents<C: Component>(
        of _: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void
    ) {
        let componentIndex = C.componentIndex
        guard hasRows(of: componentIndex) else {
            return
        }
        beginWrite(componentIndex)
        lockDepth += 1
        defer {
            lockDepth -= 1
            endWrite(componentIndex)
        }
        for table in tables where table.rowCount > 0 {
            guard let column = table.column(C.self, at: componentIndex) else {
                continue
            }
            table.entities.withUnsafeBufferPointer { ids in
                body(ids, UnsafeMutableBufferPointer(start: column.base, count: ids.count))
            }
        }
    }

    /// Whether any table that holds the component type has a row.
    @usableFromInline
    func hasRows(of componentIndex: Int) -> Bool {
        tables.contains { $0.rowCount > 0 && $0.mask.contains(componentIndex) }
    }
}
