//
//  AnyComponentStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    /// Type-erased base of the per-component-type storages of the sparse-set storage.
    ///
    /// It owns the parallel entity-index array and the paged sparse index, which do not depend on the component
    /// type. The untyped methods are the slow paths (FSM, snapshots, inspection, clone); hot paths cast to the
    /// typed subclass with `unsafeDowncast` after checking `typeID`.
    @usableFromInline
    class AnyComponentStorage {
        /// Dense, hole-free list of the entity indices that have this component; position equals dense slot.
        @exclusivity(unchecked)
        @usableFromInline final var ids = ContiguousArray<UInt32>()
        @usableFromInline final let sparse = PagedSparseIndex()
        /// The component type this storage was created for; guards `unsafeDowncast` against two types sharing an index.
        @usableFromInline final let typeID: ObjectIdentifier
        /// The runtime identifier of the component type.
        @usableFromInline final let identifier: ComponentIdentifier

        @usableFromInline
        init(typeID: ObjectIdentifier, identifier: ComponentIdentifier) {
            self.typeID = typeID
            self.identifier = identifier
        }

        @usableFromInline final var count: Int {
            ids.count
        }

        @inlinable final var isEmpty: Bool {
            ids.isEmpty
        }

        @inlinable
        final func contains(_ index: UInt32) -> Bool {
            sparse.slot(of: index) >= 0
        }

        // swiftlint:disable unavailable_function
        /// Removes the component of the entity with this index by swapping the last slot into its place.
        @usableFromInline
        func remove(_: UInt32) -> Bool {
            fatalError("abstract")
        }

        /// The entity's component.
        @usableFromInline
        func anyComponent(for _: UInt32) -> (any Component)? {
            fatalError("abstract")
        }
        // swiftlint:enable unavailable_function
    }
}
