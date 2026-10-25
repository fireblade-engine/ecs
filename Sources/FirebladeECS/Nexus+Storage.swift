//
//  Nexus+Storage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// The storage a ``Nexus`` keeps its entities and components in.
    ///
    /// The set of storages is closed: a nexus owns exactly one and switches on it once per call.
    public enum StorageKind: CaseIterable, Sendable {
        /// One dense array per component type, a paged sparse index per type, a bitset per entity.
        ///
        /// Adding and removing components is O(1) and moves no other data.
        case sparseSet

        /// The storage ``Nexus/init(storage:)`` uses by default.
        public static let `default` = StorageKind.sparseSet
    }

    /// The storage of a nexus. A closed enum instead of a protocol: every storage is concrete, so its code specializes.
    @usableFromInline
    enum Backend {
        case sparseSet(SparseSetStorage)

        init(_ kind: StorageKind) {
            switch kind {
            case .sparseSet:
                self = .sparseSet(SparseSetStorage())
            }
        }
    }
}

extension Nexus {
    /// The index of a component type, resolved once so that iterations do not ask the registry per entity.
    @usableFromInline
    struct ComponentCursor<C: Component>: Sendable {
        @usableFromInline let index: Int

        @usableFromInline
        init() {
            index = C.componentIndex
        }
    }

    /// The component of a living entity, or `nil` if the identifier is stale or the entity has no such component.
    @inlinable
    final func component<C: Component>(_ cursor: ComponentCursor<C>, for entityId: EntityIdentifier) -> C? {
        backend.get(C.self, at: cursor.index, for: entityId)
    }
}

extension Nexus.Backend {
    @inlinable var entityCount: Int {
        switch self {
        case let .sparseSet(storage):
            storage.entityCount
        }
    }

    @inlinable var totalComponentCount: Int {
        switch self {
        case let .sparseSet(storage):
            storage.totalComponentCount
        }
    }

    @inlinable var livingEntityIds: [EntityIdentifier] {
        switch self {
        case let .sparseSet(storage):
            storage.entities.livingIds
        }
    }

    @inlinable
    func insertEntity(_ entityId: EntityIdentifier) {
        switch self {
        case let .sparseSet(storage):
            storage.insertEntity(entityId)
        }
    }

    @inlinable
    @discardableResult
    func destroyEntity(_ entityId: EntityIdentifier) -> Bool {
        switch self {
        case let .sparseSet(storage):
            storage.destroyEntity(entityId)
        }
    }

    @inlinable
    func isAlive(_ entityId: EntityIdentifier) -> Bool {
        switch self {
        case let .sparseSet(storage):
            storage.isAlive(entityId)
        }
    }

    @inlinable
    func currentEntity(atIndex index: EntityIdentifier.Index) -> EntityIdentifier? {
        switch self {
        case let .sparseSet(storage):
            storage.entities.current(at: index)
        }
    }

    @inlinable
    func removeAll() {
        switch self {
        case let .sparseSet(storage):
            storage.removeAll()
        }
    }

    @inlinable
    func set<C: Component>(_ component: C, at componentIndex: Int, for entityId: EntityIdentifier) {
        switch self {
        case let .sparseSet(storage):
            storage.set(component, at: componentIndex, for: entityId)
        }
    }

    @inlinable
    func set<C: Component>(_ component: C, for entityId: EntityIdentifier) {
        set(component, at: C.componentIndex, for: entityId)
    }

    @inlinable
    func modify<C: Component>(_ type: C.Type, for entityId: EntityIdentifier, _ body: (inout C) throws -> Void) rethrows -> Bool {
        switch self {
        case let .sparseSet(storage):
            try storage.modify(type, for: entityId, body)
        }
    }

    @inlinable
    func withComponents<C: Component>(of type: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void) {
        switch self {
        case let .sparseSet(storage):
            storage.withComponents(of: type, body)
        }
    }

    @inlinable
    func get<C: Component>(_ type: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C? {
        switch self {
        case let .sparseSet(storage):
            storage.get(type, at: componentIndex, for: entityId)
        }
    }

    @inlinable
    func get<C: Component>(_ type: C.Type, for entityId: EntityIdentifier) -> C? {
        get(type, at: C.componentIndex, for: entityId)
    }

    @inlinable
    func unsafeGet<C: Component>(_ type: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C {
        switch self {
        case let .sparseSet(storage):
            storage.unsafeGet(type, at: componentIndex, for: entityId)
        }
    }

    @inlinable
    func unsafeGet<C: Component>(_ type: C.Type, for entityId: EntityIdentifier) -> C {
        unsafeGet(type, at: C.componentIndex, for: entityId)
    }

    @inlinable
    func hasStorage(for componentIndex: Int) -> Bool {
        switch self {
        case let .sparseSet(storage):
            storage.hasStorage(for: componentIndex)
        }
    }

    @inlinable
    func has(componentIndex: Int, for entityId: EntityIdentifier) -> Bool {
        switch self {
        case let .sparseSet(storage):
            storage.has(componentIndex: componentIndex, for: entityId)
        }
    }

    @inlinable
    func componentMask(of entityId: EntityIdentifier) -> Nexus.ComponentMask? {
        switch self {
        case let .sparseSet(storage):
            storage.entities.mask(of: entityId)
        }
    }

    @inlinable
    func componentIndices(of entityId: EntityIdentifier) -> [Int] {
        switch self {
        case let .sparseSet(storage):
            storage.componentIndices(of: entityId)
        }
    }

    @inlinable
    func componentCount(of entityId: EntityIdentifier) -> Int {
        switch self {
        case let .sparseSet(storage):
            storage.componentCount(of: entityId)
        }
    }

    @inlinable
    func componentIndex(of identifier: ComponentIdentifier) -> Int? {
        switch self {
        case let .sparseSet(storage):
            storage.indexByIdentifier[identifier]
        }
    }

    @inlinable
    func identifier(ofComponentIndex componentIndex: Int) -> ComponentIdentifier? {
        switch self {
        case let .sparseSet(storage):
            storage.identifier(ofComponentIndex: componentIndex)
        }
    }

    @inlinable
    @discardableResult
    func remove(componentIndex: Int, from entityId: EntityIdentifier) -> Bool {
        switch self {
        case let .sparseSet(storage):
            storage.remove(componentIndex: componentIndex, from: entityId)
        }
    }

    @inlinable
    func anyComponent(componentIndex: Int, for entityId: EntityIdentifier) -> (any Component)? {
        switch self {
        case let .sparseSet(storage):
            storage.anyComponent(componentIndex: componentIndex, for: entityId)
        }
    }
}
