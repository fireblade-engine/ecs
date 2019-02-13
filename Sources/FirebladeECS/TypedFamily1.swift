//
//  TypedFamily1.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public struct TypedFamily1<A>: TypedFamilyProtocol where A: Component {
    public let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    public func makeIterator() -> ComponentIterator1<A> {
        return ComponentIterator1(nexus, self)
    }

    public var entityAndComponents: FamilyEntitiesAndComponents1<A> {
        return FamilyEntitiesAndComponents1(nexus, self)
    }
}

public struct ComponentIterator1<A>: ComponentIteratorProtocol where A: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily1<A>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> A? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        return nexus.get(for: entityId)
    }
}

public struct FamilyEntitiesAndComponents1<A>: EntityComponentsSequenceProtocol where A: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily1<A>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (Entity, A)? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        guard
            let entity = nexus.get(entity: entityId),
            let compA: A = nexus.get(for: entityId)
            else {
                return nil
        }

        return (entity, compA)
    }
}
