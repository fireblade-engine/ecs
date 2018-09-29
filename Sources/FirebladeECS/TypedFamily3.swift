//
//  TypedFamily3.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public final class TypedFamily<A, B, C>: TypedFamilyProtocol where A: Component, B: Component, C: Component {

    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet
    public private(set) lazy var members: FamilyMembers<A, B, C> = FamilyMembers(nexus, self)

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

}

public struct FamilyMembers<A, B, C>: FamilyMembersProtocol where A: Component, B: Component, C: Component {

    public private(set) weak var nexus: Nexus?
    public let family: TypedFamily<A, B, C>

    public init(_ nexus: Nexus?, _ family: TypedFamily<A, B, C>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator<A, B, C> {
        return ComponentIterator(nexus, family)
    }
}

public struct ComponentIterator<A, B, C>: ComponentIteratorProtocol where A: Component, B: Component, C: Component {

    public private(set) weak var nexus: Nexus?
    public let memberIds: UniformEntityIdentifiers
    public var index: Int

    public init(_ nexus: Nexus?, _ family: TypedFamily<A, B, C>) {
        self.nexus = nexus
        memberIds = family.memberIds
        index = memberIds.index(before: memberIds.startIndex)
    }

    public mutating func next() -> (A, B, C)? {
        guard let entityId: EntityIdentifier = nextEntityId() else {
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
