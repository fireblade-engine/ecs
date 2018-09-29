//
//  TypedFamily1.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public final class TypedFamily1<A>: TypedFamilyProtocol where A: Component {

    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requiresAll compA: A.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

    public func makeIterator() -> ComponentIterator1<A> {
        return ComponentIterator1(nexus, self)
    }

}

public struct ComponentIterator1<A>: ComponentIteratorProtocol where A: Component {

    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ family: TypedFamily1<A>) {
        self.nexus = nexus
        memberIdsIterator = family.memberIds.makeIterator()
    }

    public mutating func next() -> A? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        return nexus?.get(for: entityId)
    }

}
