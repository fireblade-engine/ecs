//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

// swiftlint:disable large_tuple

public final class TypedFamily<A, B, C> where A: Component, B: Component, C: Component {

    internal weak var nexus: Nexus?

    public let traits: FamilyTraitSet

    internal init(_ nexus: Nexus, requiresAll compA: A.Type, _ compB: B.Type, _ compC: C.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA, compB, compC], excludesAll: excludesAll)
        defer {
            nexus.onFamilyInit(traits: traits)
        }
    }

    public private(set) lazy var members: FamilyMembers<A, B, C> = FamilyMembers(nexus, self)

    internal final var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }

}

public struct FamilyMembers<A, B, C>: LazySequenceProtocol where A: Component, B: Component, C: Component {

    private weak var nexus: Nexus?
    public let family: TypedFamily<A, B, C>

    internal init(_ nexus: Nexus?, _ family: TypedFamily<A, B, C>) {
        self.nexus = nexus
        self.family = family
    }

    public func makeIterator() -> ComponentIterator<A, B, C> {
        return ComponentIterator(nexus, family)
    }
}

public struct ComponentIterator<A, B, C>: IteratorProtocol where A: Component, B: Component, C: Component {

    private let memberIds: UniformEntityIdentifiers
    private weak var nexus: Nexus?
    private var index: Int

    public init(_ nexus: Nexus?, _ family: TypedFamily<A, B, C>) {
        self.nexus = nexus
        memberIds = family.memberIds
        index = memberIds.index(before: memberIds.startIndex)
    }

    private mutating func nextIndex() -> Int? {
        let nextIndex: Int = memberIds.index(after: index)
        guard nextIndex < memberIds.endIndex else {
            return nil
        }

        index = nextIndex
        return nextIndex
    }

    private mutating func nextEntityId() -> EntityIdentifier? {
        guard let index: Int = nextIndex() else {
            return nil
        }

        return memberIds[index]
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
