//
//  EntityIdentifierGenerator.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 26.06.20.
//

/// An entity identifier generator provides new entity
/// identifiers on entity creation.
/// It also allows entity ids to be marked for re-use.
/// Entity identifiers must be unique.
public protocol EntityIdentifierGenerator {
    /// Initialize the generator with entity ids already in use.
    /// - Parameter entityIds: The entity ids already in use. Default should be an empty array.
    init(inUse entityIds: [EntityIdentifier])

    /// Provides the next unused entity identifier.
    ///
    /// The provided entity identifier is at least unique during runtime.
    func nextId() -> EntityIdentifier

    /// Marks the given entity identifier as free and ready for re-use.
    ///
    /// Unused entity identifiers will again be provided with `nextId()`.
    /// - Parameter entityId: The entity id to be marked as unused.
    func markUnused(entityId: EntityIdentifier)
}

/// A default entity identifier generator implementation.
///
/// Provides entity ids starting at `0` incrementing until `UInt32.max`.
public struct DefaultEntityIdGenerator: EntityIdentifierGenerator {
    @usableFromInline
    final class Storage {
        @usableFromInline var stack: [UInt32]
        @usableFromInline var count: Int { stack.count }

        @usableFromInline
        init(inUse entityIds: [EntityIdentifier]) {
            stack = entityIds.reversed().map { UInt32($0.id) }
        }

        @usableFromInline
        func nextId() -> EntityIdentifier {
            if stack.count == 1 {
                defer { stack[0] += 1 }
                return EntityIdentifier(stack[0])
            } else {
                return EntityIdentifier(stack.removeLast())
            }
        }

        @usableFromInline
        func markUnused(entityId: EntityIdentifier) {
            stack.append(UInt32(entityId.id))
        }
    }

    @usableFromInline let storage: Storage

    @usableFromInline var count: Int { storage.count }

    @inlinable
    public init() {
        self.init(inUse: [EntityIdentifier(0)])
    }

    @inlinable
    public init(inUse entityIds: [EntityIdentifier]) {
        self.storage = Storage(inUse: entityIds)
    }

    @inlinable
    public func nextId() -> EntityIdentifier {
        storage.nextId()
    }

    @inlinable
    public func markUnused(entityId: EntityIdentifier) {
        storage.markUnused(entityId: entityId)
    }
}
