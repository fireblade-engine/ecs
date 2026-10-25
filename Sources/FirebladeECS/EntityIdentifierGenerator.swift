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
/// A generator hands out the generations of entity identifiers, too:
/// A slot index may be provided again after it was marked unused, but only with a higher generation,
/// so that no identifier is ever provided twice and identifiers of destroyed entities stay stale.
/// A slot whose generation can not be increased any further is retired and never provided again.
///
/// You should strive to keep entity ids tightly packed around `EntityIdentifier.Index.min` since it has an influence on the underlying memory layout.
public protocol EntityIdentifierGenerator: Sendable {
    /// Initialize the generator providing entity ids to begin with when creating new entities.
    ///
    /// Entity ids provided should be passed to `nextId()` in last out order up until the collection is empty,
    /// with the generations they have in the collection.
    /// The default is an empty collection.
    /// - Parameter initialEntityIds: The entity ids to start providing up until the collection is empty (in last out order).
    init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier

    /// Provides the next unused entity identifier.
    ///
    /// The provided entity identifier must be unique during runtime and valid (not `EntityIdentifier.invalid`).
    /// The generation of a provided identifier must be higher than the generation of every identifier
    /// with the same index that was provided before.
    func nextId() -> EntityIdentifier

    /// Marks the given entity identifier as free and ready for re-use.
    ///
    /// The index of the entity identifier will again be provided with `nextId()`, with a higher generation.
    /// - Parameter entityId: The entity id to be marked as unused.
    func markUnused(entityId: EntityIdentifier)
}

/// A default entity identifier generator implementation.
public typealias DefaultEntityIdGenerator = LinearIncrementingEntityIdGenerator

/// **Linear incrementing entity id generator**
///
/// This entity id generator creates linearly incrementing entity ids
/// unless an entity is marked as unused then the marked id is returned next in a FIFO order
/// with an increased generation.
/// Slots start at generation 1. A slot whose generation reaches `UInt32.max` is retired and never provided again.
///
/// Furthermore it respects order of entity ids on initialization, meaning the provided ids on initialization will be provided in order
/// until all are in use. After that the free entities start at the lowest available id increasing linearly skipping already in-use entity ids.
public struct LinearIncrementingEntityIdGenerator: EntityIdentifierGenerator {
    /// Internal storage for entity identifiers.
    @usableFromInline
    final class Storage: @unchecked Sendable {
        /// The bottom of the stack is the next fresh identifier (generation 1), provided once no recycled identifiers are left.
        /// The elements above it are the recycled identifiers, provided in last out order.
        @usableFromInline var stack: [EntityIdentifier]
        @usableFromInline var count: Int {
            stack.count
        }

        /// Initializes the storage with initial identifiers.
        /// - Parameter initialEntityIds: Identifiers to start with.
        @usableFromInline
        init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier {
            let initialInUse: [EntityIdentifier] = Array(initialEntityIds)
            guard let maxInUseIndex = initialInUse.map(\.index).max() else {
                stack = [Self.firstFresh(0)]
                return
            }
            precondition(maxInUseIndex < .max, "Entity index space is exhausted.")
            let inUseSet = Set(initialInUse.map(\.index)) // a set of all indices in use
            let freeSet = Set(0 ..< maxInUseIndex).subtracting(inUseSet) // all "holes" / unused / free indices below maxInUseIndex
            // order them to provide them linear increasing after all initially used are provided.
            let initialFree = freeSet.sorted(by: >).map(Self.firstFresh)
            stack = [Self.firstFresh(maxInUseIndex + 1)] + initialFree + initialInUse
        }

        /// Initializes the storage with a default identifier.
        @usableFromInline
        init() {
            stack = [Self.firstFresh(0)]
        }

        /// Creates the identifier of the first generation of a slot.
        @usableFromInline
        static func firstFresh(_ index: EntityIdentifier.Index) -> EntityIdentifier {
            EntityIdentifier(index: index, generation: 1)
        }

        /// Returns the next available identifier.
        /// - Returns: A unique entity identifier.
        @usableFromInline
        func nextId() -> EntityIdentifier {
            guard stack.count == 1 else {
                return stack.removeLast()
            }
            let fresh = stack[0]
            precondition(fresh.index < .max, "Entity index space is exhausted.")
            stack[0] = Self.firstFresh(fresh.index + 1)
            return fresh
        }

        /// Marks an identifier as unused.
        ///
        /// The slot is recycled with an increased generation, or retired once the generation would reach `UInt32.max`.
        /// - Parameter entityId: The identifier to recycle.
        @usableFromInline
        func markUnused(entityId: EntityIdentifier) {
            let nextGeneration = entityId.generation &+ 1
            guard nextGeneration < .max, nextGeneration > entityId.generation else {
                return // retired: the generation can not be increased any further without wrapping around.
            }
            stack.append(EntityIdentifier(index: entityId.index, generation: nextGeneration))
        }
    }

    @usableFromInline let storage: Storage
    @usableFromInline var count: Int {
        storage.count
    }

    /// Initializes a new linear incrementing generator with a collection of initial entity IDs.
    ///
    /// - Parameter initialEntityIds: A bidirectional collection of `EntityIdentifier`s to be used first.
    /// - Complexity: O(N log N) where N is the number of initial entity IDs.
    @inlinable
    public init<EntityIds>(startProviding initialEntityIds: EntityIds) where EntityIds: BidirectionalCollection, EntityIds.Element == EntityIdentifier {
        storage = Storage(startProviding: initialEntityIds)
    }

    /// Initializes a new linear incrementing generator starting from 0.
    /// - Complexity: O(1)
    @inlinable
    public init() {
        storage = Storage()
    }

    /// Provides the next unused entity identifier.
    ///
    /// - Returns: A unique `EntityIdentifier`.
    /// - Complexity: O(1)
    @inline(__always)
    public func nextId() -> EntityIdentifier {
        storage.nextId()
    }

    /// Marks an entity identifier as unused, allowing it to be reused.
    ///
    /// - Parameter entityId: The `EntityIdentifier` to recycle.
    /// - Complexity: O(1)
    @inline(__always)
    public func markUnused(entityId: EntityIdentifier) {
        storage.markUnused(entityId: entityId)
    }
}

extension LinearIncrementingEntityIdGenerator: Sendable {}
