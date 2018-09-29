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

    var count: Int { get }
}

public extension TypedFamilyProtocol {
    var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }

    var count: Int {
        return memberIds.count
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

    var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier> { get }
    var nexus: Nexus? { get }

    init(_ nexus: Nexus?, _ family: TypedFamily)
}
