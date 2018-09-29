//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public protocol TypedFamilyProtocol: AnyObject, Equatable, LazySequenceProtocol {

    var traits: FamilyTraitSet { get }
    var nexus: Nexus? { get }

    var count: Int { get }
}

public extension TypedFamilyProtocol {
    var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }

    var count: Int {
        return memberIds.count
    }

    static func == <Other>(lhs: Self, rhs: Other) -> Bool where Other: TypedFamilyProtocol {
        return lhs.traits == rhs.traits && lhs.nexus == rhs.nexus
    }
}

public protocol ComponentIteratorProtocol: IteratorProtocol {
    associatedtype TypedFamily: TypedFamilyProtocol

    var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier> { get }
    var nexus: Nexus? { get }

    init(_ nexus: Nexus?, _ family: TypedFamily)
}
