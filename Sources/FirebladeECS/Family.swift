//
//  Family.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

public struct Family<R> where R: ComponentsProviding {
    @usableFromInline unowned let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(nexus: Nexus, requiresAll: @autoclosure () -> (R.ComponentTypes), excludesAll: [Component.Type]) {
        let required = R(requiresAll())
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: required.componentTypes, excludesAll: excludesAll)
    }

    @inlinable public var memberIds: UnorderedSparseSet<EntityIdentifier> {
        return nexus.members(withFamilyTraits: traits)
    }

    @inlinable public  var count: Int {
        return memberIds.count
    }

    @inlinable public var isEmpty: Bool {
        return memberIds.isEmpty
    }

    @inlinable public var entities: FamilyEntities {
        return FamilyEntities(nexus, memberIds)
    }

    @inlinable
    public func canBecomeMember(_ entity: Entity) -> Bool {
        return nexus.canBecomeMember(entity, in: traits)
    }

    @inlinable
    public func isMember(_ entity: Entity) -> Bool {
        return nexus.isMember(entity, in: traits)
    }
}

extension Family {
    public struct FamilyIterator: IteratorProtocol {
        @usableFromInline var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>
        @usableFromInline unowned let nexus: Nexus

        public init(family: Family<R>) {
            self.nexus = family.nexus
            memberIdsIterator = family.memberIds.makeIterator()
        }

        public mutating func next() -> R.Components? {
            guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
                return nil
            }

            return R.getComponents(nexus: nexus, entityId: entityId)
        }
    }
}

extension Family: Sequence {
    __consuming public func makeIterator() -> FamilyIterator {
        return FamilyIterator(family: self)
    }
}
