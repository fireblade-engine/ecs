//
//  FamilyEntities.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

public struct FamilyEntities {
    public let nexus: Nexus
    public var memberIdsIterator: UnorderedSparseSetIterator<EntityIdentifier>

    public init(_ nexus: Nexus, _ memberIds: UnorderedSparseSet<EntityIdentifier>) {
        self.nexus = nexus
        memberIdsIterator = memberIds.makeIterator()
    }
}

extension FamilyEntities: IteratorProtocol {
    public mutating func next() -> Entity? {
            guard let entityId = memberIdsIterator.next() else {
                return nil
            }

            return nexus.get(entity: entityId)
        }
}

extension FamilyEntities: LazySequenceProtocol { }

// TODO: extension FamilyEntities: Equatable { }
