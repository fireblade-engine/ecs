//
//  AnyComponentStorage.swift
//  S2Storage
//

/// Type-erased base of the per-component-type storages of the sparse-set storage.
///
/// It owns the parallel entity-index array and the paged sparse index, which do not depend on the component
/// type. The untyped methods are the slow paths; hot paths cast to the typed subclass with
/// `unsafeDowncast` after checking `typeID`.
public class AnyComponentStorage {
    /// Dense, hole-free list of the entity indices that have this component; position equals dense slot.
    @exclusivity(unchecked) @usableFromInline final var ids = ContiguousArray<UInt32>()
    public final let sparse = PagedSparseIndex()
    /// The component type this storage was created for; guards `unsafeDowncast` against two types sharing an index.
    public final let typeID: ObjectIdentifier

    init(typeID: ObjectIdentifier) {
        self.typeID = typeID
    }

    public final var count: Int {
        ids.count
    }

    @inlinable
    public final var isEmpty: Bool {
        ids.isEmpty
    }

    @inlinable
    public final func contains(_ index: UInt32) -> Bool {
        sparse.slot(of: index) >= 0
    }

    /// Removes the component of the entity with this index by swapping the last slot into its place.
    public func remove(_ index: UInt32) -> Bool {
        fatalError("abstract")
    }

    /// A boxed copy of the entity's component.
    public func anyComponent(for index: UInt32) -> (any Component)? {
        fatalError("abstract")
    }
}
