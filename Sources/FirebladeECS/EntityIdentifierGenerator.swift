//
//  EntityIdentifierGenerator.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 26.06.20.
//

/// **Entity Identifier Generator**
///
/// An entity identifier generator provides new entity identifiers on entity creation.
/// It also allows entity ids to be marked as unused (to be re-usable).
///
/// You should strive to keep entity ids tightly packed around `EntityIdentifier.Identifier.min` since it has an influence on the underlying memory layout.
public protocol EntityIdentifierGenerator: Sendable {
    /// Initialize the generator providing entity ids to begin with when creating new entities.
    ///
    /// Entity ids provided should be passed to `nextId()` in last out order up until the collection is empty.
    /// The default is an empty collection.
    /// - Parameter initialEntityIds: The entity ids to start providing up until the collection is empty (in last out order).
    init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier

    /// Provides the next unused entity identifier.
    ///
    /// The provided entity identifier must be unique during runtime.
    func nextId() -> EntityIdentifier

    /// Marks the given entity identifier as free and ready for re-use.
    ///
    /// Unused entity identifiers will again be provided with `nextId()`.
    /// - Parameter entityId: The entity id to be marked as unused.
    func markUnused(entityId: EntityIdentifier)
}

/// A default entity identifier generator implementation.
public typealias DefaultEntityIdGenerator = LinearIncrementingEntityIdGenerator

/// **Linear incrementing entity id generator**
///
/// This entity id generator creates linearly incrementing entity ids
/// unless an entity is marked as unused then the marked id is returned next in a FIFO order.
///
/// Furthermore it respects order of entity ids on initialization, meaning the provided ids on initialization will be provided in order
/// until all are in use. After that the free entities start at the lowest available id increasing linearly skipping already in-use entity ids.
public struct LinearIncrementingEntityIdGenerator: EntityIdentifierGenerator {
    /// Internal storage for entity identifiers.
    @usableFromInline
    final class Storage: @unchecked Sendable {
        @usableFromInline var stack: [EntityIdentifier.Identifier]
        @usableFromInline var count: Int {
            stack.count
        }

        /// Initializes the storage with initial identifiers.
        /// - Parameter initialEntityIds: Identifiers to start with.
        @usableFromInline
        init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier {
            let initialInUse: [EntityIdentifier.Identifier] = initialEntityIds.map(\.id)
            let maxInUseValue = initialInUse.max() ?? 0
            let inUseSet = Set(initialInUse) // a set of all eIds in use
            let allSet = Set(0 ... maxInUseValue) // all eIds from 0 to including maxInUseValue
            let freeSet = allSet.subtracting(inUseSet) // all "holes" / unused / free eIds
            let initialFree = Array(freeSet).sorted().reversed() // order them to provide them linear increasing after all initially used are provided.
            stack = initialFree + initialInUse
        }

        /// Initializes the storage with a default identifier.
        @usableFromInline
        init() {
            stack = [0]
        }

        /// Returns the next available identifier.
        /// - Returns: A unique entity identifier.
        @usableFromInline
        func nextId() -> EntityIdentifier {
            guard stack.count == 1 else {
                return EntityIdentifier(stack.removeLast())
            }
            defer { stack[0] += 1 }
            return EntityIdentifier(stack[0])
        }

        /// Marks an identifier as unused.
        /// - Parameter entityId: The identifier to recycle.
        @usableFromInline
        func markUnused(entityId: EntityIdentifier) {
            stack.append(entityId.id)
        }
    }

    @usableFromInline let storage: Storage
    @usableFromInline var count: Int {
        storage.count
    }

    /// Initializes a new linear incrementing generator with a collection of initial entity IDs.
    ///
    /// - Parameter initialEntityIds: A bidirectional collection of `EntityIdentifier`s to be used first.
    @inlinable
    public init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier {
        storage = Storage(startProviding: initialEntityIds)
    }

    /// Initializes a new linear incrementing generator starting from 0.
    @inlinable
    public init() {
        storage = Storage()
    }

    /// Provides the next unused entity identifier.
    ///
    /// - Returns: A unique `EntityIdentifier`.
    @inline(__always)
    public func nextId() -> EntityIdentifier {
        storage.nextId()
    }

    /// Marks an entity identifier as unused, allowing it to be reused.
    ///
    /// - Parameter entityId: The `EntityIdentifier` to recycle.
    @inline(__always)
    public func markUnused(entityId: EntityIdentifier) {
        storage.markUnused(entityId: entityId)
    }
}

extension LinearIncrementingEntityIdGenerator: Sendable {}
