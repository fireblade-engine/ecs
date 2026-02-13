//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 21.08.19.
//

/// A group of entities that share a common set of component types.
///
/// Families are the primary way to iterate over entities in the ECS.
/// They are defined by a set of required components (`requiresAll`) and optionally excluded components (`excludesAll`).
public struct Family<each C: Component> {
    /// The Nexus managing this family.
    @usableFromInline unowned let nexus: Nexus

    /// The traits that define this family (required and excluded components).
    public let traits: FamilyTraitSet

    /// Initializes a new family.
    /// - Parameters:
    ///   - nexus: The nexus instance.
    ///   - requiresAll: The required component types.
    ///   - excludesAll: A list of excluded component types.
    public init(nexus: Nexus, requiresAll: repeat (each C).Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        
        var requiredIdentifiers: [ComponentIdentifier] = []
        // We iterate the pack to extract identifiers
        _ = (repeat requiredIdentifiers.append((each C).identifier))
        
        let excludedIdentifiers = excludesAll.map { $0.identifier }
        
        self.traits = FamilyTraitSet(requiresAll: Set(requiredIdentifiers), excludesAll: Set(excludedIdentifiers))
        nexus.onFamilyInit(traits: traits)
    }

    /// The set of entity identifiers that are members of this family.
    ///
    /// This property provides access to the underlying storage of family members managed by the `Nexus`.
    /// - Complexity: O(1)
    @inlinable var memberIds: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier> {
        nexus.members(withFamilyTraits: traits)
    }

    /// Returns the number of family member entities.
    /// - Complexity: O(1)
    @inlinable public var count: Int {
        memberIds.count
    }

    /// True if this family has no members; false otherwise.
    /// - Complexity: O(1)
    @inlinable public var isEmpty: Bool {
        memberIds.isEmpty
    }

    /// Checks if an entity can become a member of this family.
    /// - Parameter entity: The entity to check.
    /// - Returns: `true` if the entity matches the family traits.
    /// - Complexity: O(T) where T is the total number of required and excluded components.
    @inlinable
    public func canBecomeMember(_ entity: Entity) -> Bool {
        nexus.canBecomeMember(entity, in: traits)
    }

    /// Checks if an entity is currently a member of this family.
    /// - Parameter entity: The entity to check.
    /// - Returns: `true` if the entity is a member.
    /// - Complexity: O(1)
    @inlinable
    public func isMember(_ entity: Entity) -> Bool {
        nexus.isMember(entity, in: traits)
    }

    /// Destroy all member entities of this family.
    /// - Returns: True if entities where destroyed, false otherwise.
    /// - Complexity: O(N * M) where N is the number of members and M is the number of families.
    @discardableResult
    public func destroyMembers() -> Bool {
        entities.reduce(!isEmpty) { $0 && nexus.destroy(entity: $1) }
    }
}

extension Family: Equatable {
    public static func == (lhs: Family<repeat each C>, rhs: Family<repeat each C>) -> Bool {
        lhs.nexus === rhs.nexus &&
            lhs.traits == rhs.traits
    }
}

extension Family: Sequence {
    /// Creates an iterator over the components of the family members.
    /// - Complexity: O(1)
    public func makeIterator() -> ComponentsIterator {
        ComponentsIterator(family: self)
    }
}

extension Family: LazySequenceProtocol {}

// MARK: - components iterator

extension Family {
    /// An iterator over the component collections of family members.
    public struct ComponentsIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        /// Creates a new iterator for the given family.
        /// - Parameter family: The family to iterate over.
        /// - Complexity: O(1)
        public init(family: Family<repeat each C>) {
            nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        /// Advances to the next component collection and returns it, or `nil` if no next element exists.
        /// - Returns: The next component collection in the sequence, or `nil`.
        /// - Complexity: O(R) where R is the number of required components.
        public mutating func next() -> (repeat each C)? {
            guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
                return nil
            }
            return (repeat nexus.get(unsafe: entityId) as (each C))
        }
    }
}

extension Family.ComponentsIterator: LazySequenceProtocol {}
extension Family.ComponentsIterator: Sequence {}

// MARK: - entity iterator

extension Family {
    /// A collection of all entities in this family.
    /// - Complexity: O(1)
    @inlinable public var entities: EntityIterator {
        EntityIterator(family: self)
    }

    /// An iterator over the entities in the family.
    public struct EntityIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        /// Creates a new iterator for the given family.
        /// - Parameter family: The family to iterate over.
        /// - Complexity: O(1)
        public init(family: Family<repeat each C>) {
            nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        /// Advances to the next entity and returns it, or `nil` if no next element exists.
        /// - Returns: The next entity in the sequence, or `nil`.
        /// - Complexity: O(1)
        public mutating func next() -> Entity? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return Entity(nexus: nexus, id: entityId)
        }
    }
}

extension Family.EntityIterator: LazySequenceProtocol {}
extension Family.EntityIterator: Sequence {}

// MARK: - entity component iterator

extension Family {
    /// A collection of entities and their components in this family.
    /// - Complexity: O(1)
    @inlinable public var entityAndComponents: EntityComponentIterator {
        EntityComponentIterator(family: self)
    }

    /// An iterator over both the entities and their components in the family.
    public struct EntityComponentIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        /// Creates a new iterator for the given family.
        /// - Parameter family: The family to iterate over.
        /// - Complexity: O(1)
        public init(family: Family<repeat each C>) {
            nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        /// Advances to the next entity and components pair and returns it, or `nil` if no next element exists.
        /// - Returns: The next entity and components pair in the sequence, or `nil`.
        /// - Complexity: O(R) where R is the number of required components.
        public mutating func next() -> (Entity, repeat each C)? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            let entity = Entity(nexus: nexus, id: entityId)
            let components = (repeat nexus.get(unsafe: entityId) as (each C))
            return (entity, repeat each components)
        }
    }
}

extension Family.EntityComponentIterator: LazySequenceProtocol {}
extension Family.EntityComponentIterator: Sequence {}

// MARK: - member creation

extension Family {
    /// Create a new entity with components required by this family.
    ///
    /// Since the created entity will meet the requirements of this family it
    /// will automatically become member of this family.
    /// - Parameter components: The components required by this family.
    /// - Returns: The newly created entity.
    @discardableResult
    public func createMember(with components: repeat each C) -> Entity {
        nexus.createEntity(with: repeat each components)
    }
}

extension Family: Sendable {}
extension Family.ComponentsIterator: Sendable {}
extension Family.EntityIterator: Sendable {}
extension Family.EntityComponentIterator: Sendable {}
