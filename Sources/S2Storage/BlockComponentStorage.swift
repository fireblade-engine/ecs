//
//  BlockComponentStorage.swift
//  S2Storage
//

/// Geometry of the block-allocated dense array.
public enum BlockLayout {
    /// log2 of the number of elements per block.
    public static let shift = 10
    /// The number of elements per block.
    public static let size = 1 << shift
}

/// A hoistable copy of a block table: element `slot` lives at `table[slot >> shift][slot & (size - 1)]`.
public struct BlockView<C: Component> {
    @usableFromInline let table: UnsafeMutablePointer<UnsafeMutablePointer<C>?>

    @inlinable
    init(table: UnsafeMutablePointer<UnsafeMutablePointer<C>?>) {
        self.table = table
    }

    @inlinable
    public subscript(slot: Int) -> C {
        unsafeAddress {
            UnsafePointer(table[slot >> BlockLayout.shift].unsafelyUnwrapped + (slot & (BlockLayout.size - 1)))
        }
        nonmutating unsafeMutableAddress {
            table[slot >> BlockLayout.shift].unsafelyUnwrapped + (slot & (BlockLayout.size - 1))
        }
    }
}

/// Benchmark variant of `ComponentStorage`: the dense array is a list of fixed-size blocks allocated by hand
/// instead of a `ContiguousArray`.
///
/// Blocks never move, so growth copies nothing and element addresses stay stable until removal; iteration
/// pays one extra indirection per element lookup. Elements are initialized and deinitialized by hand, so
/// non-trivial fields (`String`, `Array`) are released exactly once: on removal, on replacement and in `deinit`.
public final class BlockComponentStorage<C: Component>: AnyComponentStorage {
    @usableFromInline var blocks: UnsafeMutablePointer<UnsafeMutablePointer<C>?>
    @usableFromInline var blockTableCapacity = 4
    @usableFromInline var allocatedBlocks = 0

    override public init() {
        blocks = .allocate(capacity: blockTableCapacity)
        blocks.initialize(repeating: nil, count: blockTableCapacity)
        super.init()
    }

    deinit {
        var remaining = ids.count
        for block in 0 ..< allocatedBlocks {
            let pointer = blocks[block].unsafelyUnwrapped
            pointer.deinitialize(count: min(remaining, BlockLayout.size))
            remaining -= min(remaining, BlockLayout.size)
            pointer.deallocate()
        }
        blocks.deallocate()
    }

    @inlinable
    var blockView: BlockView<C> {
        BlockView(table: blocks)
    }

    @inlinable
    subscript(slot: Int) -> C {
        unsafeAddress { UnsafePointer(pointer(at: slot)) }
        unsafeMutableAddress { pointer(at: slot) }
    }

    @inlinable
    func slot(of index: UInt32) -> Int {
        sparse.slot(of: index)
    }

    func insert(_ component: C, for index: UInt32) {
        let slot = ids.count
        let block = slot >> BlockLayout.shift
        if block == allocatedBlocks {
            growTableIfNeeded()
            blocks[block] = .allocate(capacity: BlockLayout.size)
            allocatedBlocks += 1
        }
        (blocks[block].unsafelyUnwrapped + (slot & (BlockLayout.size - 1))).initialize(to: component)
        sparse.set(index, slot: slot)
        ids.append(index)
    }

    private func growTableIfNeeded() {
        guard allocatedBlocks == blockTableCapacity else {
            return
        }
        let newCapacity = blockTableCapacity * 2
        let newTable = UnsafeMutablePointer<UnsafeMutablePointer<C>?>.allocate(capacity: newCapacity)
        newTable.moveInitialize(from: blocks, count: blockTableCapacity)
        (newTable + blockTableCapacity).initialize(repeating: nil, count: newCapacity - blockTableCapacity)
        blocks.deallocate()
        blocks = newTable
        blockTableCapacity = newCapacity
    }

    @inlinable
    func pointer(at slot: Int) -> UnsafeMutablePointer<C> {
        blocks[slot >> BlockLayout.shift].unsafelyUnwrapped + (slot & (BlockLayout.size - 1))
    }

    override public func remove(_ index: UInt32) -> Bool {
        let slot = sparse.slot(of: index)
        guard slot >= 0 else {
            return false
        }
        let last = ids.count - 1
        let target = pointer(at: slot)
        target.deinitialize(count: 1)
        if slot != last {
            target.moveInitialize(from: pointer(at: last), count: 1)
            ids[slot] = ids[last]
            sparse.set(ids[slot], slot: slot)
        }
        ids.removeLast()
        sparse.clear(index)
        return true
    }

    override public func anyComponent(for index: UInt32) -> (any Component)? {
        let slot = sparse.slot(of: index)
        return slot >= 0 ? self[slot] : nil
    }

    override public func assign(any component: any Component, to index: UInt32) -> Bool {
        let slot = sparse.slot(of: index)
        guard slot >= 0, let typed = component as? C else {
            return false
        }
        self[slot] = typed
        return true
    }
}
