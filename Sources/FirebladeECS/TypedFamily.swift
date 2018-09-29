//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public protocol TypedFamilyProtocol: AnyObject {
    associatedtype Members: FamilyMembersProtocol

    var traits: FamilyTraitSet { get }
    var nexus: Nexus? { get }
    var memberIds: UniformEntityIdentifiers { get }
    var members: Members { get set }
}

public extension TypedFamilyProtocol {
    var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }
}

public protocol FamilyMembersProtocol: LazySequenceProtocol {
    associatedtype TypedFamily: TypedFamilyProtocol

    var nexus: Nexus? { get }
    var family: TypedFamily { get }

    init(_ nexus: Nexus?, _ family: TypedFamily)
}

public protocol ComponentIteratorProtocol: IteratorProtocol {
    associatedtype TypedFamily: TypedFamilyProtocol

    var memberIds: UniformEntityIdentifiers { get }
    var nexus: Nexus? { get }
    var index: Int { get set }

    init(_ nexus: Nexus?, _ family: TypedFamily)
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
