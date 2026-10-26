//
//  SparseSetStorage+Access.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus.SparseSetStorage {
    /// Starts a write access to the component of an entity that spans several statements, for `_modify` accessors.
    ///
    /// The type is write locked and structural changes trap until ``endAccess(_:)``.
    /// - Returns: The address of the component in the buffer, or `nil` if the entity has no such component.
    @inlinable
    func beginAccess<C: Component>(_: C.Type, for entityId: EntityIdentifier) -> UnsafeMutablePointer<C>? {
        let componentIndex = C.componentIndex
        guard entities.isAlive(entityId), let storage = existing(C.self, at: componentIndex) else {
            return nil
        }
        let slot = storage.slot(of: entityId.index)
        guard slot >= 0 else {
            return nil
        }
        beginWrite(componentIndex)
        lockDepth += 1
        return storage.base + slot
    }

    /// Ends the write access started by ``beginAccess(_:for:)``.
    @inlinable
    func endAccess(_ componentIndex: Int) {
        lockDepth -= 1
        endWrite(componentIndex)
    }

    /// Removes a component whose value was moved out of the buffer and not put back, without releasing it.
    @inlinable
    func discardMovedOut<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        requireUnlocked()
        let componentIndex = C.componentIndex
        guard let storage = existing(C.self, at: componentIndex) else {
            return
        }
        storage.removeSwapMovedOut(entityId.index)
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
}
