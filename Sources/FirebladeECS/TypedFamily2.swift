//
//  TypedFamily2.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public struct TypedFamily2<A, B>: TypedFamilyProtocol where A: Component, B: Component {
    public let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    public func makeIterator() -> ComponentIterator2<A, B> {
        return ComponentIterator2(nexus, self)
    }

    public var entityAndComponents: FamilyEntitiesAndComponents2<A, B> {
        return FamilyEntitiesAndComponents2<A, B>(nexus, self)
    }
}

public struct ComponentIterator2<A, B>: ComponentIteratorProtocol where A: Component, B: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily2<A, B>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (A, B)? {
        guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
            return nil
        }

        guard
            let compA: A = nexus.get(for: entityId),
            let compB: B = nexus.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB)
    }
}

public struct FamilyEntitiesAndComponents2<A, B>: EntityComponentsSequenceProtocol where A: Component, B: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily2<A, B>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (Entity, A, B)? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        guard
            let entity = nexus.get(entity: entityId),
            let compA: A = nexus.get(for: entityId),
            let compB: B = nexus.get(for: entityId)
            else {
                return nil
        }

        return (entity, compA, compB)
    }
}
