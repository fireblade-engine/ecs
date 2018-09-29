//
//  TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public protocol TypedFamilyProtocol: AnyObject, Equatable, LazySequenceProtocol {
    associatedtype EntityComponentsSequence: EntityComponentsSequenceProtocol

    var traits: FamilyTraitSet { get }
    var nexus: Nexus? { get }

    var count: Int { get }

    var entities: FamilyEntities { get }
    var entityAndComponents: EntityComponentsSequence { get }
}

public extension TypedFamilyProtocol {
    var memberIds: UniformEntityIdentifiers {
        return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
    }

    var count: Int {
        return memberIds.count
    }

    var entities: FamilyEntities {
        return FamilyEntities(nexus, memberIds)
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

public protocol EntityComponentsSequenceProtocol: LazySequenceProtocol, IteratorProtocol {
    associatedtype TypedFamily: TypedFamilyProtocol

    var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier> { get }
    var nexus: Nexus? { get }

    init(_ nexus: Nexus?, _ family: TypedFamily)
}

public struct FamilyEntities: LazySequenceProtocol, IteratorProtocol {
    public private(set) weak var nexus: Nexus?
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus?, _ memberIds: UniformEntityIdentifiers) {
        self.nexus = nexus
        memberIdsIterator = memberIds.makeIterator()
    }

    public mutating func next() -> Entity? {
        guard let entityId = memberIdsIterator.next() else {
            return nil
        }

        return nexus?.get(entity: entityId)
    }

}
