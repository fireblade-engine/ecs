//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 21.08.19.
//

public struct Family<R> where R: FamilyRequirementsManaging {
    @usableFromInline unowned let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(nexus: Nexus, requiresAll: @autoclosure () -> R.ComponentTypes, excludesAll: [Component.Type]) {
        let required = R(requiresAll())
        self.nexus = nexus
        let traits = FamilyTraitSet(requiresAll: required.componentTypes, excludesAll: excludesAll)
        self.traits = traits
        nexus.onFamilyInit(traits: traits)
    }

    @inlinable var memberIds: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier> {
        nexus.members(withFamilyTraits: traits)
    }

    /// Returns the number of family member entities.
    @inlinable public var count: Int {
        memberIds.count
    }

    /// True if this family has no members; false otherwise.
    @inlinable public var isEmpty: Bool {
        memberIds.isEmpty
    }

    @inlinable
    public func canBecomeMember(_ entity: Entity) -> Bool {
        nexus.canBecomeMember(entity, in: traits)
    }

    @inlinable
    public func isMember(_ entity: Entity) -> Bool {
        nexus.isMember(entity, in: traits)
    }

    /// Destroy all member entities of this family.
    /// - Returns: True if entities where destroyed, false otherwise.
    @discardableResult
    public func destroyMembers() -> Bool {
        entities.reduce(!isEmpty) { $0 && nexus.destroy(entity: $1) }
    }

    /// Create a member entity with the given components assigned.
    /// - Parameter builder: The family member builder.
    /// - Returns: The newly created member entity.
    @discardableResult
    public func createMember(@FamilyMemberBuilder<R> using builder: () -> R.Components) -> Entity {
        self.createMember(with: builder())
    }
}

extension Family: Equatable {
    public static func == (lhs: Family<R>, rhs: Family<R>) -> Bool {
        lhs.nexus === rhs.nexus &&
            lhs.traits == rhs.traits
    }
}

extension Family: Sequence {
    public func makeIterator() -> ComponentsIterator {
        ComponentsIterator(family: self)
    }
}

extension Family: LazySequenceProtocol { }

// MARK: - components iterator
extension Family {
    public struct ComponentsIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> R.Components? {
            guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
                return nil
            }

            return R.components(nexus: nexus, entityId: entityId)
        }
    }
}

extension Family.ComponentsIterator: LazySequenceProtocol { }
extension Family.ComponentsIterator: Sequence { }

// MARK: - entity iterator
extension Family {
    @inlinable public var entities: EntityIterator {
        EntityIterator(family: self)
    }

    public struct EntityIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> Entity? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return Entity(nexus: nexus, id: entityId)
        }
    }
}

extension Family.EntityIterator: LazySequenceProtocol { }
extension Family.EntityIterator: Sequence { }

// MARK: - entity component iterator
extension Family {
    @inlinable public var entityAndComponents: EntityComponentIterator {
        EntityComponentIterator(family: self)
    }

    public struct EntityComponentIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>.ElementIterator
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> R.EntityAndComponents? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }
            return R.entityAndComponents(nexus: nexus, entityId: entityId)
        }
    }
}

extension Family.EntityComponentIterator: LazySequenceProtocol { }
extension Family.EntityComponentIterator: Sequence { }

// MARK: - member creation
extension Family {
    /// Create a new entity with components required by this family.
    ///
    /// Since the created entity will meet the requirements of this family it
    /// will automatically become member of this family.
    /// - Parameter components: The components required by this family.
    /// - Returns: The newly created entity.
    @discardableResult
    public func createMember(with components: R.Components) -> Entity {
        R.createMember(nexus: nexus, components: components)
    }
}
