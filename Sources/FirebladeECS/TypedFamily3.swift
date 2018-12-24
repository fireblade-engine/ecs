//
//  TypedFamily3.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public final class TypedFamily3<A, B, C>: TypedFamilyProtocol where A: Component, B: Component, C: Component {
    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    public func makeIterator() -> ComponentIterator3<A, B, C> {
        return ComponentIterator3(nexus, self)
    }

    public var entityAndComponents: FamilyEntitiesAndComponents3<A, B, C> {
        return FamilyEntitiesAndComponents3(nexus, self)
    }
}

public struct ComponentIterator3<A, B, C>: ComponentIteratorProtocol where A: Component, B: Component, C: Component {
    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily3<A, B, C>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (A, B, C)? {
        guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
            return nil
        }

        guard
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId),
            let compC: C = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB, compC)
    }
}

public struct FamilyEntitiesAndComponents3<A, B, C>: EntityComponentsSequenceProtocol where A: Component, B: Component, C: Component {
    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily3<A, B, C>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (Entity, A, B, C)? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        guard
            let entity = nexus?.get(entity: entityId),
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId),
            let compC: C = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (entity, compA, compB, compC)
    }
}
