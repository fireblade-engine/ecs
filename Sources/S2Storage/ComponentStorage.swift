//
//  ComponentStorage.swift
//  S2Storage
//

/// The dense storage of one component type in a sparse-set storage: a hole-free `ContiguousArray<C>` whose
/// position `i` belongs to the entity at `ids[i]`, addressed through the paged sparse index.
///
/// Removal swaps the last element into the freed slot, so it is O(1) and keeps the array dense.
public final class ComponentStorage<C: Component>: AnyComponentStorage {
    @usableFromInline var dense = ContiguousArray<C>()

    override public init() {
        super.init()
    }

    /// The address of dense slot 0. Only valid while the storage is neither modified nor reallocated, which
    /// the storage provider guarantees for the duration of an iteration. Requires `count > 0`.
    @inlinable
    var base: UnsafeMutablePointer<C> {
        dense.withUnsafeMutableBufferPointer { $0.baseAddress.unsafelyUnwrapped }
    }

    @inlinable
    func slot(of index: UInt32) -> Int {
        sparse.slot(of: index)
    }

    func insert(_ component: C, for index: UInt32) {
        sparse.set(index, slot: dense.count)
        dense.append(component)
        ids.append(index)
    }

    override public func remove(_ index: UInt32) -> Bool {
        let slot = sparse.slot(of: index)
        guard slot >= 0 else {
            return false
        }
        let last = dense.count - 1
        if slot != last {
            dense.swapAt(slot, last)
            ids.swapAt(slot, last)
            sparse.set(ids[slot], slot: slot)
        }
        dense.removeLast()
        ids.removeLast()
        sparse.clear(index)
        return true
    }

    override public func anyComponent(for index: UInt32) -> (any Component)? {
        let slot = sparse.slot(of: index)
        return slot >= 0 ? dense[slot] : nil
    }

    override public func assign(any component: any Component, to index: UInt32) -> Bool {
        let slot = sparse.slot(of: index)
        guard slot >= 0, let typed = component as? C else {
            return false
        }
        dense[slot] = typed
        return true
    }
}
