//
//  EntityTable.swift
//  S2Storage
//

/// Entity bookkeeping shared by every storage: liveness, the free list of reusable indices and the
/// per-entity component bitset.
public struct EntityTable {
    @usableFromInline var masks = ContiguousArray<ComponentMask>()
    @usableFromInline var alive = ContiguousArray<Bool>()
    @usableFromInline var freeList = ContiguousArray<UInt32>()

    /// The number of living entities.
    public private(set) var liveCount = 0

    public init() {}

    /// One more than the largest index ever handed out.
    public var capacity: Int {
        masks.count
    }

    @inlinable
    public func isAlive(_ entity: EntityID) -> Bool {
        Int(entity.index) < alive.count && alive[Int(entity.index)]
    }

    /// The component set of `entity`; empty for dead entities.
    @inlinable
    public func mask(of entity: EntityID) -> ComponentMask {
        Int(entity.index) < masks.count ? masks[Int(entity.index)] : ComponentMask()
    }

    public mutating func create() -> EntityID {
        liveCount += 1
        if let index = freeList.popLast() {
            alive[Int(index)] = true
            return EntityID(index: index)
        }
        let index = UInt32(masks.count)
        masks.append(ComponentMask())
        alive.append(true)
        return EntityID(index: index)
    }

    /// Marks `entity` dead and clears its component set. The caller removes the components first.
    public mutating func destroy(_ entity: EntityID) -> Bool {
        guard isAlive(entity) else {
            return false
        }
        alive[Int(entity.index)] = false
        masks[Int(entity.index)] = ComponentMask()
        freeList.append(entity.index)
        liveCount -= 1
        return true
    }

    @inlinable
    mutating func insert(_ componentIndex: Int, into entity: EntityID) {
        masks[Int(entity.index)].insert(componentIndex)
    }

    @inlinable
    mutating func remove(_ componentIndex: Int, from entity: EntityID) {
        masks[Int(entity.index)].remove(componentIndex)
    }
}
