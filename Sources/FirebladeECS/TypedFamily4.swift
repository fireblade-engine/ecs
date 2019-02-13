//
//  TypedFamily4.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public struct TypedFamily4<A, B, C, D>: TypedFamilyProtocol where A: Component, B: Component, C: Component, D: Component {
    public let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, _ compD: D.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC, compD], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    public func makeIterator() -> ComponentIterator4<A, B, C, D> {
        return ComponentIterator4(nexus, self)
    }

    public var entityAndComponents: FamilyEntitiesAndComponents4<A, B, C, D> {
        return FamilyEntitiesAndComponents4(nexus, self)
    }
}

public struct ComponentIterator4<A, B, C, D>: ComponentIteratorProtocol where A: Component, B: Component, C: Component, D: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily4<A, B, C, D>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (A, B, C, D)? {
        guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
            return nil
        }

        guard
            let compA: A = nexus.get(for: entityId),
            let compB: B = nexus.get(for: entityId),
            let compC: C = nexus.get(for: entityId),
            let compD: D = nexus.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB, compC, compD)
    }
}

public struct FamilyEntitiesAndComponents4<A, B, C, D>: EntityComponentsSequenceProtocol where A: Component, B: Component, C: Component, D: Component {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ family: TypedFamily4<A, B, C, D>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (Entity, A, B, C, D)? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        guard
            let entity = nexus.get(entity: entityId),
            let compA: A = nexus.get(for: entityId),
            let compB: B = nexus.get(for: entityId),
            let compC: C = nexus.get(for: entityId),
            let compD: D = nexus.get(for: entityId)
            else {
                return nil
        }

        return (entity, compA, compB, compC, compD)
    }
}
