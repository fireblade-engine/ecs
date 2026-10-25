//
//  S2Nexus.swift
//  S2Storage
//

// Arity-numbered parameter names (r0, w0) mirror the per-arity overloads.
// swiftlint:disable identifier_name

/// The non-generic nexus of 2.0: it owns one storage through a closed enum and switches on it once per call.
///
/// Every typed call (`set`, `get`, `forEach`, ...) switches over `Backend` and then runs the storage's
/// specialized code, so the cost of choosing the storage is one predictable branch per call, never per
/// entity. There is no protocol between the nexus and the storages: the set of storages is closed, and the
/// per-arity iteration overloads exist once per storage as concrete `@inlinable` methods instead of as
/// protocol requirements.
public final class S2Nexus {
    /// Which storage a nexus is created with.
    public enum StorageKind: CaseIterable, Sendable {
        case sparseSet
        case archetype

        /// The storage chosen by the S2 benchmarks.
        public static let `default` = StorageKind.sparseSet
    }

    @usableFromInline
    enum Backend {
        case sparse(SparseSetStorage)
        case archetype(ArchetypeStorage)
    }

    @usableFromInline let backend: Backend

    public init(storage: StorageKind = .default) {
        switch storage {
        case .sparseSet: backend = .sparse(SparseSetStorage())
        case .archetype: backend = .archetype(ArchetypeStorage())
        }
    }

    // MARK: Entities

    @inlinable
    public var entityCount: Int {
        switch backend {
        case let .sparse(storage): storage.entityCount
        case let .archetype(storage): storage.entityCount
        }
    }

    @inlinable
    public func createEntity() -> EntityID {
        switch backend {
        case let .sparse(storage): storage.createEntity()
        case let .archetype(storage): storage.createEntity()
        }
    }

    @inlinable
    @discardableResult
    public func destroyEntity(_ entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.destroyEntity(entity)
        case let .archetype(storage): storage.destroyEntity(entity)
        }
    }

    @inlinable
    public func isAlive(_ entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.isAlive(entity)
        case let .archetype(storage): storage.isAlive(entity)
        }
    }

    // MARK: Typed component access

    @inlinable
    public func set<C: Component>(_ component: C, for entity: EntityID) {
        switch backend {
        case let .sparse(storage): storage.set(component, for: entity)
        case let .archetype(storage): storage.set(component, for: entity)
        }
    }

    @inlinable
    public func get<C: Component>(_ type: C.Type, for entity: EntityID) -> C? {
        switch backend {
        case let .sparse(storage): storage.get(type, for: entity)
        case let .archetype(storage): storage.get(type, for: entity)
        }
    }

    @inlinable
    public func modify<C: Component>(_ type: C.Type, for entity: EntityID, _ body: (inout C) -> Void) -> Bool {
        switch backend {
        case let .sparse(storage): storage.modify(type, for: entity, body)
        case let .archetype(storage): storage.modify(type, for: entity, body)
        }
    }

    @inlinable
    @discardableResult
    public func remove<C: Component>(_ type: C.Type, from entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.remove(type, from: entity)
        case let .archetype(storage): storage.remove(type, from: entity)
        }
    }

    @inlinable
    public func has<C: Component>(_ type: C.Type, for entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.has(type, for: entity)
        case let .archetype(storage): storage.has(type, for: entity)
        }
    }

    // MARK: Untyped slow paths

    public func componentIndices(of entity: EntityID) -> [Int] {
        switch backend {
        case let .sparse(storage): storage.componentIndices(of: entity)
        case let .archetype(storage): storage.componentIndices(of: entity)
        }
    }

    public func has(componentIndex: Int, for entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.has(componentIndex: componentIndex, for: entity)
        case let .archetype(storage): storage.has(componentIndex: componentIndex, for: entity)
        }
    }

    @discardableResult
    public func remove(componentIndex: Int, from entity: EntityID) -> Bool {
        switch backend {
        case let .sparse(storage): storage.remove(componentIndex: componentIndex, from: entity)
        case let .archetype(storage): storage.remove(componentIndex: componentIndex, from: entity)
        }
    }

    public func anyComponent(componentIndex: Int, for entity: EntityID) -> (any Component)? {
        switch backend {
        case let .sparse(storage): storage.anyComponent(componentIndex: componentIndex, for: entity)
        case let .archetype(storage): storage.anyComponent(componentIndex: componentIndex, for: entity)
        }
    }

    public func assign(any component: any Component, to entity: EntityID) {
        switch backend {
        case let .sparse(storage): storage.assign(any: component, to: entity)
        case let .archetype(storage): storage.assign(any: component, to: entity)
        }
    }

    // MARK: Families

    @inlinable
    public func canBecomeMember(_ entity: EntityID, in filter: FamilyFilter) -> Bool {
        switch backend {
        case let .sparse(storage): storage.canBecomeMember(entity, in: filter)
        case let .archetype(storage): storage.canBecomeMember(entity, in: filter)
        }
    }

    @inlinable
    public func forEach<R0: Component>(reading r0: R0.Type, where filter: FamilyFilter = .none, _ body: (R0) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: r0, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: r0, where: filter, body)
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component>(reading r0: R0.Type, _ r1: R1.Type, where filter: FamilyFilter = .none, _ body: (R0, R1) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: r0, r1, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: r0, r1, where: filter, body)
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, R2: Component, R3: Component>(reading r0: R0.Type, _ r1: R1.Type, _ r2: R2.Type, _ r3: R3.Type, where filter: FamilyFilter = .none, _ body: (R0, R1, R2, R3) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: r0, r1, r2, r3, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: r0, r1, r2, r3, where: filter, body)
        }
    }

    @inlinable
    public func forEach<R0: Component, W0: Component>(reading r0: R0.Type, writing w0: W0.Type, where filter: FamilyFilter = .none, _ body: (R0, inout W0) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: r0, writing: w0, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: r0, writing: w0, where: filter, body)
        }
    }

    @inlinable
    public func forEach<R0: Component, R1: Component, W0: Component>(reading r0: R0.Type, _ r1: R1.Type, writing w0: W0.Type, where filter: FamilyFilter = .none, _ body: (R0, R1, inout W0) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: r0, r1, writing: w0, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: r0, r1, writing: w0, where: filter, body)
        }
    }

    @inlinable
    public func forEach<each R: Component>(reading types: repeat (each R).Type, where filter: FamilyFilter = .none, _ body: (repeat each R) -> Void) {
        switch backend {
        case let .sparse(storage): storage.forEach(reading: repeat each types, where: filter, body)
        case let .archetype(storage): storage.forEach(reading: repeat each types, where: filter, body)
        }
    }

    // MARK: Bulk access

    /// Gives `body` the entity indices and component values of every contiguous run of `type`: one run on the
    /// sparse-set storage, one per table holding the type on the archetype storage.
    @inlinable
    public func withComponents<C: Component>(
        of type: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void
    ) {
        switch backend {
        case let .sparse(storage): storage.withComponents(of: type, body)
        case let .archetype(storage): storage.withComponents(of: type, body)
        }
    }
}
