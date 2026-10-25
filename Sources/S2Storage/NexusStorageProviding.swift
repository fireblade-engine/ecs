//
//  NexusStorageProviding.swift
//  S2Storage
//

// Arity-numbered parameter names (r0, r1, w0) are the clearest names the per-arity overloads have.
// swiftlint:disable identifier_name multiline_parameters

/// The storage behind a nexus: entities, their components and the typed iteration over families.
///
/// **Shape.** The protocol has no associated types, but its typed operations are generic methods, and the
/// intended client is generic over the conformer (`Nexus<Storage: NexusStorageProviding>`). With a concrete
/// `Storage` the compiler specializes every call, hoists the typed storage lookup out of the entity loop and
/// never boxes. Holding an `any NexusStorageProviding` instead makes each call an existential dispatch plus
/// an unspecialized generic call; that costs once per call, not per entity, because the per-entity loop lives
/// inside the conformer. `Nexus.init(storage: .default)` resolves to a static member on a constrained
/// extension (`where Self == SparseSetStorage`).
///
/// **Safety (D4).** Nothing here hands out a pointer that outlives a call. Mutation happens through scoped
/// closures. While a scoped access or an iteration is running, any structural change (creating or destroying
/// an entity, adding or removing a component, replacing a component value) traps.
///
/// **Entities.** `EntityID.index` is reused after `destroyEntity`. Passing a dead entity to a mutating
/// operation traps; read operations (`get`, `has`, `modify`, `remove`) report absence instead.
public protocol NexusStorageProviding: AnyObject {
    init()

    // MARK: Entities

    /// The number of living entities.
    var entityCount: Int { get }

    func createEntity() -> EntityID

    /// Removes every component of `entity` and frees its index. Returns `false` for a dead entity.
    @discardableResult
    func destroyEntity(_ entity: EntityID) -> Bool

    func isAlive(_ entity: EntityID) -> Bool

    // MARK: Typed component access

    /// Inserts `component`, or replaces the entity's existing value of that type.
    func set<C: Component>(_ component: C, for entity: EntityID)

    /// A copy of the component, or `nil` when the entity has none.
    func get<C: Component>(_ type: C.Type, for entity: EntityID) -> C?

    /// Runs `body` with in-place access to the component. Returns `false`, without calling `body`, when the
    /// entity has no such component.
    func modify<C: Component>(_ type: C.Type, for entity: EntityID, _ body: (inout C) -> Void) -> Bool

    /// Removes the component. Returns `false` when the entity has none.
    @discardableResult
    func remove<C: Component>(_ type: C.Type, from entity: EntityID) -> Bool

    func has<C: Component>(_ type: C.Type, for entity: EntityID) -> Bool

    // MARK: Untyped slow paths (finite-state machines, snapshots, editors)

    /// The component indices `entity` currently has.
    func componentIndices(of entity: EntityID) -> [Int]

    func has(componentIndex: Int, for entity: EntityID) -> Bool

    @discardableResult
    func remove(componentIndex: Int, from entity: EntityID) -> Bool

    /// A boxed copy of the component with that index.
    func anyComponent(componentIndex: Int, for entity: EntityID) -> (any Component)?

    /// Inserts or replaces the component, whatever its dynamic type.
    func assign(any component: any Component, to entity: EntityID)

    // MARK: Families

    /// Whether `entity` is a member of the family described by `filter`.
    func canBecomeMember(_ entity: EntityID, in filter: FamilyFilter) -> Bool

    /// Calls `body` for every entity that has `R0` and matches `filter`.
    func forEach<R0: Component>(
        reading r0: R0.Type, where filter: FamilyFilter, _ body: (R0) -> Void
    )

    func forEach<R0: Component, R1: Component>(
        reading r0: R0.Type, _ r1: R1.Type, where filter: FamilyFilter, _ body: (R0, R1) -> Void
    )

    func forEach<R0: Component, R1: Component, R2: Component, R3: Component>(
        reading r0: R0.Type, _ r1: R1.Type, _ r2: R2.Type, _ r3: R3.Type,
        where filter: FamilyFilter, _ body: (R0, R1, R2, R3) -> Void
    )

    /// Reads `R0`, writes `W0`. `R0` and `W0` must be distinct types.
    func forEach<R0: Component, W0: Component>(
        reading r0: R0.Type, writing w0: W0.Type, where filter: FamilyFilter, _ body: (R0, inout W0) -> Void
    )

    /// Reads `R0` and `R1`, writes `W0`. All three must be distinct types.
    func forEach<R0: Component, R1: Component, W0: Component>(
        reading r0: R0.Type, _ r1: R1.Type, writing w0: W0.Type,
        where filter: FamilyFilter, _ body: (R0, R1, inout W0) -> Void
    )

    /// Fallback above the per-arity overloads (D7): any number of reads through a parameter pack.
    func forEach<each R: Component>(
        reading types: repeat (each R).Type, where filter: FamilyFilter, _ body: (repeat each R) -> Void
    )

    // MARK: Bulk access

    /// Gives `body` the dense entity indices and the component values of every contiguous run of that
    /// component type, index `i` of the first buffer owning value `i` of the second.
    ///
    /// A sparse-set storage has exactly one run per type. An archetype storage has one run per table that
    /// holds the type, so the number of calls is not part of the contract. The buffers are valid for the
    /// duration of the call only.
    func withComponents<C: Component>(
        of type: C.Type, _ body: (_ entities: UnsafeBufferPointer<UInt32>, _ components: UnsafeMutableBufferPointer<C>) -> Void
    )
}

extension NexusStorageProviding {
    public func forEach<R0: Component>(reading r0: R0.Type, _ body: (R0) -> Void) {
        forEach(reading: r0, where: .none, body)
    }

    public func forEach<R0: Component, R1: Component>(reading r0: R0.Type, _ r1: R1.Type, _ body: (R0, R1) -> Void) {
        forEach(reading: r0, r1, where: .none, body)
    }

    public func forEach<R0: Component, W0: Component>(reading r0: R0.Type, writing w0: W0.Type, _ body: (R0, inout W0) -> Void) {
        forEach(reading: r0, writing: w0, where: .none, body)
    }

    public func forEach<R0: Component, R1: Component, W0: Component>(
        reading r0: R0.Type, _ r1: R1.Type, writing w0: W0.Type, _ body: (R0, R1, inout W0) -> Void
    ) {
        forEach(reading: r0, r1, writing: w0, where: .none, body)
    }
}
