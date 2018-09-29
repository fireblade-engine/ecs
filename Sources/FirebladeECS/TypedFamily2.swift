//
//  TypedFamily2.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public final class TypedFamily2<A, B>: TypedFamilyProtocol where A: Component, B: Component {

    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet
    public lazy var members: FamilyMembers2<A, B> = FamilyMembers2(nexus, self)

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

}

public struct FamilyMembers2<A, B>: FamilyMembersProtocol where A: Component, B: Component {

    public private(set) weak var nexus: Nexus?
    public let family: TypedFamily2<A, B>

    public init(_ nexus: Nexus?, _ family: TypedFamily2<A, B>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator2<A, B> {
        return ComponentIterator2(nexus, family)
    }
}

public struct ComponentIterator2<A, B>: ComponentIteratorProtocol where A: Component, B: Component {

    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily2<A, B>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> (A, B)? {
        guard let entityId: EntityIdentifier = memberIdsIterator.next() else {
            return nil
        }

        guard
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB)
    }

}
