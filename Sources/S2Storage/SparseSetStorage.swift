//
//  SparseSetStorage.swift
//  S2Storage
//

// Arity-numbered names (s0, b0, i0) mirror the per-arity overloads.
// swiftlint:disable identifier_name function_body_length

/// Sparse-set storage: one dense array per component type, a paged sparse index per type, a bitset per entity.
///
/// - Adding or removing a component touches one type's arrays only: O(1), no data of other components moves.
/// - Iterating a family walks the smallest participating dense array and looks the other components up
///   through their sparse indices: one lookup per extra component and entity.
/// - Random access (`get`) is a sparse lookup plus an array read.
public final class SparseSetStorage: NexusStorageProviding {
    @exclusivity(unchecked) @usableFromInline var entities = EntityTable()
    /// Indexed by `Component.componentIndex`; `nil` until the type is first used.
    @exclusivity(unchecked) @usableFromInline var storages = ContiguousArray<AnyComponentStorage?>()
    /// Greater than zero while a scoped access or iteration runs; structural changes trap then.
    @exclusivity(unchecked) @usableFromInline var lockDepth = 0

    public required init() {}

    // MARK: Helpers

    @inlinable
    func existing<C: Component>(_: C.Type) -> ComponentStorage<C>? {
        let index = C.componentIndex
        guard index < storages.count, let storage = storages[index] else {
            return nil
        }
        return unsafeDowncast(storage, to: ComponentStorage<C>.self)
    }

    @usableFromInline
    func storage<C: Component>(creating _: C.Type) -> ComponentStorage<C> {
        if let storage = existing(C.self) {
            return storage
        }
        let index = C.componentIndex
        precondition(index >= 0 && index < ComponentMask.capacity, "component index \(index) is out of range")
        while storages.count <= index {
            storages.append(nil)
        }
        let storage = ComponentStorage<C>()
        storages[index] = storage
        return storage
    }

    @inlinable
    func requireUnlocked() {
        precondition(lockDepth == 0, "structural change while a scoped access or iteration is running")
    }

    // MARK: Entities

    public var entityCount: Int {
        entities.liveCount
    }

    public func createEntity() -> EntityID {
        requireUnlocked()
        return entities.create()
    }

    @discardableResult
    public func destroyEntity(_ entity: EntityID) -> Bool {
        requireUnlocked()
        guard entities.isAlive(entity) else {
            return false
        }
        entities.mask(of: entity).forEachIndex { componentIndex in
            _ = storages[componentIndex]?.remove(entity.index)
        }
        return entities.destroy(entity)
    }

    public func isAlive(_ entity: EntityID) -> Bool {
        entities.isAlive(entity)
    }

    // MARK: Typed component access

    @inlinable
    public func set<C: Component>(_ component: C, for entity: EntityID) {
        requireUnlocked()
        precondition(entities.isAlive(entity), "set on a dead entity")
        let storage = storage(creating: C.self)
        let slot = storage.slot(of: entity.index)
        if slot >= 0 {
            storage.dense[slot] = component
        } else {
            storage.insert(component, for: entity.index)
            entities.insert(C.componentIndex, into: entity)
        }
    }

    @inlinable
    public func get<C: Component>(_: C.Type, for entity: EntityID) -> C? {
        guard let storage = existing(C.self) else {
            return nil
        }
        let slot = storage.slot(of: entity.index)
        return slot >= 0 ? storage.dense[slot] : nil
    }

    @inlinable
    public func modify<C: Component>(_: C.Type, for entity: EntityID, _ body: (inout C) -> Void) -> Bool {
        guard let storage = existing(C.self) else {
            return false
        }
        let slot = storage.slot(of: entity.index)
        guard slot >= 0 else {
            return false
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        body(&storage.dense[slot])
        return true
    }

    @inlinable
    @discardableResult
    public func remove<C: Component>(_: C.Type, from entity: EntityID) -> Bool {
        requireUnlocked()
        guard let storage = existing(C.self), storage.removeSwap(entity.index) else {
            return false
        }
        entities.remove(C.componentIndex, from: entity)
        return true
    }

    @inlinable
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
        guard entities.mask(of: entity).contains(componentIndex), let storage = storages[componentIndex] else {
            return false
        }
        _ = storage.remove(entity.index)
        entities.remove(componentIndex, from: entity)
        return true
    }

    public func anyComponent(componentIndex: Int, for entity: EntityID) -> (any Component)? {
        guard componentIndex < storages.count else {
            return nil
        }
        return storages[componentIndex]?.anyComponent(for: entity.index)
    }

    public func assign(any component: any Component, to entity: EntityID) {
        set(component, for: entity)
    }

    // MARK: Families

    public func canBecomeMember(_ entity: EntityID, in filter: FamilyFilter) -> Bool {
        entities.isAlive(entity) && filter.accepts(entities.mask(of: entity))
    }

    @inlinable
    func smallest(_ lhs: AnyComponentStorage, _ rhs: AnyComponentStorage) -> AnyComponentStorage {
        lhs.count <= rhs.count ? lhs : rhs
    }

    @inlinable
    public func forEach<R0: Component>(reading _: R0.Type, where filter: FamilyFilter, _ body: (R0) -> Void) {
        guard let s0 = existing(R0.self), !s0.isEmpty else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let b0 = s0.base
        if filter.isEmpty {
            for slot in 0 ..< s0.count {
                body(b0[slot])
            }
            return
        }
        let ids = s0.ids
        let masks = entities.masks
        for slot in 0 ..< ids.count where filter.accepts(masks[Int(ids[slot])]) {
            body(b0[slot])
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component>(reading _: R0.Type, _: R1.Type, where filter: FamilyFilter, _ body: (R0, R1) -> Void) {
        guard let s0 = existing(R0.self), !s0.isEmpty, let s1 = existing(R1.self), !s1.isEmpty else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let b0 = s0.base, b1 = s1.base
        let v0 = s0.sparse.view, v1 = s1.sparse.view
        let ids = smallest(s0, s1).ids
        let masks = entities.masks
        let useMask = !filter.isEmpty
        for id in ids {
            let i0 = v0.slot(of: id), i1 = v1.slot(of: id)
            guard i0 >= 0, i1 >= 0, !useMask || filter.accepts(masks[Int(id)]) else {
                continue
            }
            body(b0[i0], b1[i1])
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, R2: Component, R3: Component>(
        reading _: R0.Type, _: R1.Type, _: R2.Type, _: R3.Type,
        where filter: FamilyFilter, _ body: (R0, R1, R2, R3) -> Void
    ) {
        guard let s0 = existing(R0.self), !s0.isEmpty, let s1 = existing(R1.self), !s1.isEmpty,
              let s2 = existing(R2.self), !s2.isEmpty, let s3 = existing(R3.self), !s3.isEmpty
        else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let b0 = s0.base, b1 = s1.base, b2 = s2.base, b3 = s3.base
        let v0 = s0.sparse.view, v1 = s1.sparse.view, v2 = s2.sparse.view, v3 = s3.sparse.view
        let ids = smallest(smallest(s0, s1), smallest(s2, s3)).ids
        let masks = entities.masks
        let useMask = !filter.isEmpty
        for id in ids {
            let i0 = v0.slot(of: id), i1 = v1.slot(of: id), i2 = v2.slot(of: id), i3 = v3.slot(of: id)
            guard i0 >= 0, i1 >= 0, i2 >= 0, i3 >= 0, !useMask || filter.accepts(masks[Int(id)]) else {
                continue
            }
            body(b0[i0], b1[i1], b2[i2], b3[i3])
        }
    }

    @inlinable
    public func forEach<R0: Component, W0: Component>(
        reading _: R0.Type, writing _: W0.Type, where filter: FamilyFilter, _ body: (R0, inout W0) -> Void
    ) {
        guard let s0 = existing(R0.self), !s0.isEmpty, let w0 = existing(W0.self), !w0.isEmpty else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let b0 = s0.base, c0 = w0.base
        let v0 = s0.sparse.view, x0 = w0.sparse.view
        let ids = smallest(s0, w0).ids
        let masks = entities.masks
        let useMask = !filter.isEmpty
        for id in ids {
            let i0 = v0.slot(of: id), j0 = x0.slot(of: id)
            guard i0 >= 0, j0 >= 0, !useMask || filter.accepts(masks[Int(id)]) else {
                continue
            }
            body(b0[i0], &c0[j0])
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, W0: Component>(
        reading _: R0.Type, _: R1.Type, writing _: W0.Type, where filter: FamilyFilter, _ body: (R0, R1, inout W0) -> Void
    ) {
        guard let s0 = existing(R0.self), !s0.isEmpty, let s1 = existing(R1.self), !s1.isEmpty,
              let w0 = existing(W0.self), !w0.isEmpty
        else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let b0 = s0.base, b1 = s1.base, c0 = w0.base
        let v0 = s0.sparse.view, v1 = s1.sparse.view, x0 = w0.sparse.view
        let ids = smallest(smallest(s0, s1), w0).ids
        let masks = entities.masks
        let useMask = !filter.isEmpty
        for id in ids {
            let i0 = v0.slot(of: id), i1 = v1.slot(of: id), j0 = x0.slot(of: id)
            guard i0 >= 0, i1 >= 0, j0 >= 0, !useMask || filter.accepts(masks[Int(id)]) else {
                continue
            }
            body(b0[i0], b1[i1], &c0[j0])
        }
    }

    @inlinable
    public func forEach<each R: Component>(reading _: repeat (each R).Type, where filter: FamilyFilter, _ body: (repeat each R) -> Void) {
        let cursors = (repeat SparseCursor(existing((each R).self)))
        var present = true
        var driver: AnyComponentStorage?
        repeat SparseCursor.accumulate(each cursors, &present, &driver)
        guard present, let driver else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        let ids = driver.ids
        let masks = entities.masks
        let useMask = !filter.isEmpty
        for id in ids {
            var member = !useMask || filter.accepts(masks[Int(id)])
            repeat SparseCursor.check(each cursors, id, &member)
            guard member else {
                continue
            }
            body(repeat (each cursors).value(id))
        }
    }

    // MARK: Bulk access

    public func withComponents<C: Component>(
        of _: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void
    ) {
        guard let storage = existing(C.self), !storage.isEmpty else {
            return
        }
        lockDepth += 1
        defer { lockDepth -= 1 }
        storage.ids.withUnsafeBufferPointer { ids in
            storage.dense.withUnsafeMutableBufferPointer { components in
                body(ids, components)
            }
        }
    }
}

/// Hoisted per-type state of a parameter-pack iteration over a sparse-set storage.
public struct SparseCursor<C: Component> {
    @usableFromInline let owner: AnyComponentStorage?
    @usableFromInline let base: UnsafeMutablePointer<C>
    @usableFromInline let view: SparseIndexView

    @inlinable
    init(_ storage: ComponentStorage<C>?) {
        if let storage, !storage.isEmpty {
            owner = storage
            base = storage.base
            view = storage.sparse.view
        } else {
            owner = nil
            base = UnsafeMutablePointer<C>(bitPattern: MemoryLayout<C>.alignment).unsafelyUnwrapped
            view = SparseIndexView(table: .init(bitPattern: 8).unsafelyUnwrapped, capacity: 0)
        }
    }

    /// Tracks whether every cursor has a non-empty storage, and which storage is the smallest.
    @inlinable
    static func accumulate(_ cursor: Self, _ present: inout Bool, _ driver: inout AnyComponentStorage?) {
        guard let owner = cursor.owner else {
            present = false
            return
        }
        if let current = driver, current.count <= owner.count {
            return
        }
        driver = owner
    }

    @inlinable
    static func check(_ cursor: Self, _ id: UInt32, _ member: inout Bool) {
        member = member && cursor.view.slot(of: id) >= 0
    }

    /// Only called after `check` found the entity in this storage.
    @inlinable
    func value(_ id: UInt32) -> C {
        base[view.slot(of: id)]
    }
}
