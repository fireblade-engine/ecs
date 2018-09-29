//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public protocol TypedFamilyProtocol: AnyObject, LazySequenceProtocol {

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
}

public protocol ComponentIteratorProtocol: IteratorProtocol {
    associatedtype TypedFamily: TypedFamilyProtocol

    var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier> { get }
    var nexus: Nexus? { get }

    init(_ nexus: Nexus?, _ family: TypedFamily)
}
