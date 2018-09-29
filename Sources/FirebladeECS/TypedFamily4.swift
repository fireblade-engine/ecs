//
//  TypedFamily4.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public final class TypedFamily4<A, B, C, D>: TypedFamilyProtocol where A: Component, B: Component, C: Component, D: Component {
    public private(set) weak var nexus: Nexus?
    public let traits: FamilyTraitSet
    public lazy var members: FamilyMembers4<A, B, C, D> = FamilyMembers4(nexus, self)

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, _ compD: D.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC, compD], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

}

public struct FamilyMembers4<A, B, C, D>: FamilyMembersProtocol where A: Component, B: Component, C: Component, D: Component {

    public private(set) weak var nexus: Nexus?
    public let family: TypedFamily4<A, B, C, D>

    public init(_ nexus: Nexus?, _ family: TypedFamily4<A, B, C, D>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator4<A, B, C, D> {
        return ComponentIterator4(nexus, family)
    }
}

public struct ComponentIterator4<A, B, C, D>: ComponentIteratorProtocol where A: Component, B: Component, C: Component, D: Component {

    public private(set) weak var nexus: Nexus?
    public let memberIds: UniformEntityIdentifiers
    public var index: Int = -1

    public init(_ nexus: Nexus?, _ family: TypedFamily4<A, B, C, D>) {
        self.nexus = nexus
        memberIds = family.memberIds
    }

    public mutating func next() -> (A, B, C, D)? {
        guard let entityId: EntityIdentifier = nextEntityId() else {
            return nil
        }

        guard
            let compA: A = nexus?.get(for: entityId),
            let compB: B = nexus?.get(for: entityId),
            let compC: C = nexus?.get(for: entityId),
            let compD: D = nexus?.get(for: entityId)
            else {
                return nil
        }

        return (compA, compB, compC, compD)
    }

}
