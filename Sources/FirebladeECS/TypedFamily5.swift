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
    public lazy var members: FamilyMembers5<A, B, C, D, E> = FamilyMembers5(nexus, self)

    public init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, _ compD: D.Type, _ compE: E.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC, compD, compE], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

}

public struct FamilyMembers5<A, B, C, D, E>: FamilyMembersProtocol where A: Component, B: Component, C: Component, D: Component, E: Component {

    public private(set) weak var nexus: Nexus?
    public let family: TypedFamily5<A, B, C, D, E>

    public init(_ nexus: Nexus?, _ family: TypedFamily5<A, B, C, D, E>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator5<A, B, C, D, E> {
        return ComponentIterator5(nexus, family)
    }
}

public struct ComponentIterator5<A, B, C, D, E>: ComponentIteratorProtocol where A: Component, B: Component, C: Component, D: Component, E: Component {

    public private(set) weak var nexus: Nexus?
    public let memberIds: UniformEntityIdentifiers
    public var index: Int = -1

    public init(_ nexus: Nexus?, _ family: TypedFamily5<A, B, C, D, E>) {
        self.nexus = nexus
        memberIds = family.memberIds
    }

    public mutating func next() -> (A, B, C, D, E)? {
        guard let entityId: EntityIdentifier = nextEntityId() else {
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
