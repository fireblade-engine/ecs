//
//  TypedFamily5.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public final class TypedFamily5<A, B, C, D, E>: TypedFamilyProtocol where A: Component, B: Component, C: Component, D: Component, E: Component {
    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, _ compD: D.Type, _ compE: E.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC, compD, compE], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    public func makeIterator() -> ComponentIterator5<A, B, C, D, E> {
        return ComponentIterator5(nexus, self)
    }

    public var entityAndComponents: FamilyEntitiesAndComponents5<A, B, C, D, E> {
        return FamilyEntitiesAndComponents5(nexus, self)
    }

}

public struct ComponentIterator5<A, B, C, D, E>: ComponentIteratorProtocol where A: Component, B: Component, C: Component, D: Component, E: Component {

    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily5<A, B, C, D, E>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (A, B, C, D, E)? {
        guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
            return nil
        }

        guard
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId),
            let compC: C = nexus?.get(for: entityId),
            let compD: D = nexus?.get(for: entityId),
            let compE: E = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB, compC, compD, compE)
    }

}

public struct FamilyEntitiesAndComponents5<A, B, C, D, E>: EntityComponentsSequenceProtocol where A: Component, B: Component, C: Component, D: Component, E: Component {
    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily5<A, B, C, D, E>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (Entity, A, B, C, D, E)? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        guard
            let entity = nexus?.get(entity: entityId),
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId),
            let compC: C = nexus?.get(for: entityId),
            let compD: D = nexus?.get(for: entityId),
            let compE: E = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (entity, compA, compB, compC, compD, compE)
    }
}
