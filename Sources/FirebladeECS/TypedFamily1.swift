//
//  TypedFamily1.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public final class TypedFamily1<A>: TypedFamilyProtocol where A: Component {

    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet
    public lazy var members: FamilyMembers1<A> = FamilyMembers1(nexus, self)

    public init(_ nexus: Nexus, requiresAll compA: A.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

}

public struct FamilyMembers1<A>: FamilyMembersProtocol where A: Component {

    public private(set) weak var nexus: Nexus?
    public let family: TypedFamily1<A>

    public init(_ nexus: Nexus?, _ family: TypedFamily1<A>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator1<A> {
        return ComponentIterator1(nexus, family)
    }
}

public struct ComponentIterator1<A>: ComponentIteratorProtocol where A: Component {

    public private(set) weak var nexus: Nexus?
    public let memberIds: UniformEntityIdentifiers
    public var index: Int = -1

    public init(_ nexus: Nexus?, _ family: TypedFamily1<A>) {
        self.nexus = nexus
        memberIds = family.memberIds
    }

    public mutating func next() -> A? {
        guard let entityId: EntityIdentifier = nextEntityId() else {
            return nil
        }

        guard
            let compA: A = nexus?.get(for: entityId)
            else {
                return nil
        }

        return compA
    }

}
