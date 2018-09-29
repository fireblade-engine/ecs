//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public protocol TypedFamilyProtocol: AnyObject {
    var traits: FamilyTraitSet { get }
    var nexus: Nexus? { get }
    var memberIds: UniformEntityIdentifiers { get }
}

public extension TypedFamilyProtocol {
    var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }
}

public protocol ComponentIteratorProtocol: IteratorProtocol {
    var memberIds: UniformEntityIdentifiers { get }
    var nexus: Nexus? { get }
    var index: Int { get set }
}

public protocol FamilyMembersProtocol: LazySequenceProtocol {
    var nexus: Nexus? { get }
}

internal extension ComponentIteratorProtocol {
    internal mutating func nextIndex() -> Int? {
        let nextIndex: Int = memberIds.index(after: index)
        guard nextIndex < memberIds.endIndex else {
            return nil
        }

        index = nextIndex
        return nextIndex
    }

    internal mutating func nextEntityId() -> EntityIdentifier? {
        guard let index: Int = nextIndex() else {
            return nil
        }

        return memberIds[index]
    }
}
