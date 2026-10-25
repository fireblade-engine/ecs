//
//  SparseSetStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Sparse-set storage: one dense array per component type, a paged sparse index per type, a bitset per entity.
    ///
    /// - Adding or removing a component touches one type's arrays only: O(1), no data of other components moves.
    /// - Random access (`get`) is a sparse lookup plus an array read.
    /// - Entity bookkeeping (liveness, component bitset) lives in the ``EntityTable``.
    ///
    /// The storage traps on misuse instead of corrupting memory: a structural change (adding or removing a component
    /// or an entity) while a scoped access runs, a second write access to a type that is being written, a read of a type
    /// that is being written, and two component types that share an index.
    ///
    /// The scoped-access lock (`lockDepth`, `activeWrites`) guards `modify` and `withComponents`, which product code
    /// does not call yet: with class components writes go through the references, and the scoped writing
    /// iteration arrives with value-type components (PR 8/9). Until then only the tests exercise the traps.
    ///
    /// Soundness of `@exclusivity(unchecked)`: the stored properties change only in structural changes and in the
    /// `beginWrite`/`endWrite`/`lockDepth` bookkeeping. Structural changes are blocked while a scoped access runs
    /// (`requireUnlocked`), storages are never removed while a scope is open, and a single thread uses a nexus at a time,
    /// so no access to them overlaps a change.
    @usableFromInline
    final class SparseSetStorage {
        @exclusivity(unchecked)
        @usableFromInline var entities = EntityTable()
        /// Indexed by `Component.componentIndex`; `nil` until the type is first used. Grows with the highest index used.
        @exclusivity(unchecked)
        @usableFromInline var storages = ContiguousArray<AnyComponentStorage?>()
        /// The index of every component type that has a storage, by its runtime identifier.
        @exclusivity(unchecked)
        @usableFromInline var indexByIdentifier: [ComponentIdentifier: Int] = [:]
        /// Greater than zero while a scoped access runs; structural changes trap then.
        @exclusivity(unchecked)
        @usableFromInline var lockDepth = 0
        /// Component types with a running write access (`modify`, `withComponents`).
        @exclusivity(unchecked)
        @usableFromInline var activeWrites = ComponentMask()
        /// Component types with a running read span (`componentSpan(reading:)`, `forEachComponentSpan`). Writes to them trap.
        @exclusivity(unchecked)
        @usableFromInline var activeReads = ComponentMask()

        @usableFromInline
        init() {}

        // MARK: Helpers

        @inlinable
        func existing<C: Component>(_: C.Type) -> ComponentStorage<C>? {
            existing(C.self, at: C.componentIndex)
        }

        @inlinable
        func existing<C: Component>(_: C.Type, at index: Int) -> ComponentStorage<C>? {
            guard index >= 0, index < storages.count, let storage = storages[index] else {
                return nil
            }
            precondition(storage.typeID == ObjectIdentifier(C.self), "component index \(index) is used by two component types")
            return unsafeDowncast(storage, to: ComponentStorage<C>.self)
        }

        @usableFromInline
        func storage<C: Component>(creating _: C.Type, at index: Int) -> ComponentStorage<C> {
            if let storage = existing(C.self, at: index) {
                return storage
            }
            precondition(index >= 0 && index < ComponentIndexRegistry.indexLimit, "component index \(index) is out of range")
            while storages.count <= index {
                storages.append(nil)
            }
            // Components are value types: a class would alias its storage slot and bypass change tracking. The macro
            // rejects classes at compile time, a hand-written conformance is only caught here, in debug builds.
            assert(!(C.self is AnyClass), "component type \(C.self) is a class; components must be structs or enums")
            let storage = ComponentStorage<C>()
            storages[index] = storage
            indexByIdentifier[storage.identifier] = index
            return storage
        }

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

        // MARK: Entities

        @usableFromInline var entityCount: Int {
            entities.liveCount
        }

        @usableFromInline
        func insertEntity(_ entityId: EntityIdentifier) {
            requireUnlocked()
            entities.insert(entityId)
        }

        /// Removes all components of the entity and frees its slot.
        ///
        /// The removed components are released last, after the slot is free, so a `deinit` that re-enters sees consistent state.
        @usableFromInline
        @discardableResult
        func destroyEntity(_ entityId: EntityIdentifier) -> Bool {
            requireUnlocked()
            guard let mask = entities.mask(of: entityId) else {
                return false
            }
            var removed: [any Component] = []
            mask.forEachIndex { componentIndex in
                if let component = storages[componentIndex]?.remove(entityId.index) {
                    removed.append(component)
                }
            }
            let destroyed = entities.remove(entityId)
            withExtendedLifetime(removed) {}
            return destroyed
        }

        @inlinable
        func isAlive(_ entityId: EntityIdentifier) -> Bool {
            entities.isAlive(entityId)
        }

        /// Removes all entities and components, and forgets all component types.
        @usableFromInline
        func removeAll() {
            requireUnlocked()
            // Components are released last, so a `deinit` that re-enters sees the emptied storage.
            let released = storages
            entities = EntityTable()
            storages = []
            indexByIdentifier.removeAll()
            withExtendedLifetime(released) {}
        }

        // MARK: Typed component access

        /// Adds a component to a living entity, or replaces the one it has.
        @inlinable
        func set<C: Component>(_ component: C, at componentIndex: Int, for entityId: EntityIdentifier) {
            requireUnlocked()
            precondition(entities.isAlive(entityId), "set on a dead entity")
            let storage = storage(creating: C.self, at: componentIndex)
            let slot = storage.slot(of: entityId.index)
            if slot >= 0 {
                storage[slot] = component
            } else {
                storage.insert(component, for: entityId.index)
                entities.insert(componentIndex, into: entityId)
            }
        }

        @inlinable
        func set<C: Component>(_ component: C, for entityId: EntityIdentifier) {
            set(component, at: C.componentIndex, for: entityId)
        }

        @inlinable
        func get<C: Component>(_: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C? {
            requireReadable(componentIndex)
            guard entities.isAlive(entityId), let storage = existing(C.self, at: componentIndex) else {
                return nil
            }
            let slot = storage.slot(of: entityId.index)
            return slot >= 0 ? storage[slot] : nil
        }

        @inlinable
        func get<C: Component>(_ type: C.Type, for entityId: EntityIdentifier) -> C? {
            get(type, at: C.componentIndex, for: entityId)
        }

        /// The component of a living entity that must have it.
        ///
        /// Checks the generation of the identifier and that the entity has the component: a stale identifier or a
        /// missing component traps with a message instead of reading another entity's component.
        @inlinable
        func unsafeGet<C: Component>(_: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C {
            requireReadable(componentIndex)
            guard entities.isAlive(entityId), let storage = existing(C.self, at: componentIndex) else {
                preconditionFailure("entity \(entityId) is not alive or has no component \(C.self)")
            }
            let slot = storage.slot(of: entityId.index)
            precondition(slot >= 0, "entity \(entityId) has no component \(C.self)")
            return storage[slot]
        }

        @inlinable
        func unsafeGet<C: Component>(_ type: C.Type, for entityId: EntityIdentifier) -> C {
            unsafeGet(type, at: C.componentIndex, for: entityId)
        }

        /// Gives `body` write access to the component of an entity.
        /// - Returns: `false` if the entity has no such component.
        @inlinable
        func modify<C: Component>(_: C.Type, for entityId: EntityIdentifier, _ body: (inout C) throws -> Void) rethrows -> Bool {
            let componentIndex = C.componentIndex
            guard entities.isAlive(entityId), let storage = existing(C.self, at: componentIndex) else {
                return false
            }
            let slot = storage.slot(of: entityId.index)
            guard slot >= 0 else {
                return false
            }
            beginWrite(componentIndex)
            lockDepth += 1
            defer {
                lockDepth -= 1
                endWrite(componentIndex)
            }
            try body(&storage[slot])
            return true
        }

        @inlinable
        @discardableResult
        func remove<C: Component>(_: C.Type, at componentIndex: Int, from entityId: EntityIdentifier) -> Bool {
            requireUnlocked()
            guard entities.isAlive(entityId), let storage = existing(C.self, at: componentIndex), let removed = storage.removeSwap(entityId.index) else {
                return false
            }
            entities.remove(componentIndex, from: entityId)
            // released last: a `deinit` that re-enters sees the component gone from storage and entity
            withExtendedLifetime(removed) {}
            return true
        }

        @inlinable
        @discardableResult
        func remove<C: Component>(_ type: C.Type, from entityId: EntityIdentifier) -> Bool {
            remove(type, at: C.componentIndex, from: entityId)
        }

        /// Whether storage for the type exists.
        @inlinable
        func hasStorage(for componentIndex: Int) -> Bool {
            componentIndex >= 0 && componentIndex < storages.count && storages[componentIndex] != nil
        }

        @inlinable
        func has(componentIndex: Int, for entityId: EntityIdentifier) -> Bool {
            entities.mask(of: entityId)?.contains(componentIndex) ?? false
        }

        // MARK: Untyped slow paths

        /// The indices of the component types of a living entity, ascending.
        @usableFromInline
        func componentIndices(of entityId: EntityIdentifier) -> [Int] {
            var result: [Int] = []
            entities.mask(of: entityId)?.forEachIndex { result.append($0) }
            return result
        }

        /// The number of components of a living entity.
        @usableFromInline
        func componentCount(of entityId: EntityIdentifier) -> Int {
            entities.mask(of: entityId)?.count ?? 0
        }

        /// The number of component instances in all storages.
        @usableFromInline var totalComponentCount: Int {
            storages.reduce(0) { $0 + ($1?.count ?? 0) }
        }

        @usableFromInline
        func identifier(ofComponentIndex componentIndex: Int) -> ComponentIdentifier? {
            componentIndex >= 0 && componentIndex < storages.count ? storages[componentIndex]?.identifier : nil
        }

        @usableFromInline
        @discardableResult
        func remove(componentIndex: Int, from entityId: EntityIdentifier) -> Bool {
            requireUnlocked()
            guard entities.mask(of: entityId)?.contains(componentIndex) == true, let storage = storages[componentIndex] else {
                return false
            }
            let removed = storage.remove(entityId.index)
            entities.remove(componentIndex, from: entityId)
            withExtendedLifetime(removed) {}
            return true
        }

        @usableFromInline
        func anyComponent(componentIndex: Int, for entityId: EntityIdentifier) -> (any Component)? {
            requireReadable(componentIndex)
            guard entities.isAlive(entityId), componentIndex >= 0, componentIndex < storages.count else {
                return nil
            }
            return storages[componentIndex]?.anyComponent(for: entityId.index)
        }

        // MARK: Bulk access

        /// Gives `body` the entity indices and component values of the type as contiguous buffers, with write access.
        @inlinable
        func withComponents<C: Component>(
            of _: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void
        ) {
            let componentIndex = C.componentIndex
            guard let storage = existing(C.self, at: componentIndex), !storage.isEmpty else {
                return
            }
            beginWrite(componentIndex)
            lockDepth += 1
            defer {
                lockDepth -= 1
                endWrite(componentIndex)
            }
            storage.ids.withUnsafeBufferPointer { ids in
                body(ids, UnsafeMutableBufferPointer(start: storage.base, count: ids.count))
            }
        }
    }
}
