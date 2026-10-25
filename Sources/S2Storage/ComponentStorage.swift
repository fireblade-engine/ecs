//
//  ComponentStorage.swift
//  S2Storage
//

/// The dense storage of one component type in a sparse-set storage: a hole-free buffer whose position `i`
/// belongs to the entity at `ids[i]`, addressed through the paged sparse index.
///
/// The values live in memory this class owns, so a pointer to slot 0 never comes from a `withUnsafe…` scope
/// and no array is ever swapped out while a closure runs: nested `get`, `modify` and iteration over the same
/// type see the real data. Elements are initialized and deinitialized by hand; `deinit` releases the live ones.
/// Removal swaps the last element into the freed slot, so it is O(1) and keeps the buffer dense.
public final class ComponentStorage<C: Component>: AnyComponentStorage {
    /// Address of slot 0; dangling (never dereferenced) while `capacity` is 0.
    @exclusivity(unchecked) @usableFromInline var base: UnsafeMutablePointer<C>
    @exclusivity(unchecked) @usableFromInline var capacity = 0

    public init() {
        base = UnsafeMutablePointer<C>(bitPattern: MemoryLayout<C>.alignment).unsafelyUnwrapped
        super.init(typeID: ObjectIdentifier(C.self))
    }

    deinit {
        base.deinitialize(count: ids.count)
        if capacity > 0 {
            base.deallocate()
        }
    }

    @inlinable
    subscript(slot: Int) -> C {
        unsafeAddress { UnsafePointer(base + slot) }
        unsafeMutableAddress { base + slot }
    }

    @inlinable
    func slot(of index: UInt32) -> Int {
        sparse.slot(of: index)
    }

    @inlinable
    func insert(_ component: C, for index: UInt32) {
        let slot = ids.count
        if slot == capacity {
            grow()
        }
        (base + slot).initialize(to: component)
        sparse.set(index, slot: slot)
        ids.append(index)
    }

    @usableFromInline
    func grow() {
        let newCapacity = max(8, capacity * 2)
        let newBase = UnsafeMutablePointer<C>.allocate(capacity: newCapacity)
        newBase.moveInitialize(from: base, count: ids.count)
        if capacity > 0 {
            base.deallocate()
        }
        base = newBase
        capacity = newCapacity
    }

    override public func remove(_ index: UInt32) -> Bool {
        removeSwap(index)
    }

    /// Typed, inlinable swap-remove; the provider's typed `remove` calls this so the work is specialized
    /// in the client instead of running through the generic class's unspecialized virtual method.
    ///
    /// The removed value is moved out first and released last, after `ids`, the sparse index and the buffer are
    /// consistent again, so a `deinit` that re-enters the storage sees a valid state.
    @inlinable
    func removeSwap(_ index: UInt32) -> Bool {
        let slot = sparse.slot(of: index)
        guard slot >= 0 else {
            return false
        }
        let last = ids.count - 1
        let removed = (base + slot).move()
        if slot != last {
            (base + slot).moveInitialize(from: base + last, count: 1)
            ids[slot] = ids[last]
            sparse.set(ids[slot], slot: slot)
        }
        ids.removeLast()
        sparse.clear(index)
        withExtendedLifetime(removed) {}
        return true
    }

    override public func anyComponent(for index: UInt32) -> (any Component)? {
        let slot = sparse.slot(of: index)
        return slot >= 0 ? self[slot] : nil
    }
}
