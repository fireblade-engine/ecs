//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public class Nexus {
    public weak var delegate: NexusEventDelegate?

    /// - Index: index value matching entity identifier shifted to Int
    /// - Value: each element is a entity instance
    @usableFromInline var entityStorage: UnorderedSparseSet<Entity>

    /// - Key: component type identifier
    /// - Value: each element is a component instance of the same type (uniform). New component instances are appended.
    @usableFromInline internal var componentsByType: [ComponentIdentifier: ManagedContiguousArray<Component>]

    /// - Key: entity id as index
    /// - Value: each element is a component identifier associated with this entity
    @usableFromInline internal var componentIdsByEntity: [EntityIdentifier: Set<ComponentIdentifier>]

    /// - Values: entity ids that are currently not used
    @usableFromInline internal var freeEntities: ContiguousArray<EntityIdentifier>

    @usableFromInline internal var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier>]

    public init() {
        entityStorage = UnorderedSparseSet<Entity>()
        componentsByType = [:]
        componentIdsByEntity = [:]
        freeEntities = ContiguousArray<EntityIdentifier>()
        familyMembersByTraits = [:]
    }

    public final func clear() {
        var iter = entityStorage.makeIterator()
        while let entity = iter.next() {
            destroy(entity: entity)
        }

        entityStorage.removeAll()
        freeEntities.removeAll()

        assert(entityStorage.isEmpty)
        assert(componentsByType.values.reduce(0) { $0 + $1.count } == 0)
        assert(componentIdsByEntity.values.reduce(0) { $0 + $1.count } == 0)
        assert(freeEntities.isEmpty)
        assert(familyMembersByTraits.values.reduce(0) { $0 + $1.count } == 0)

        componentsByType.removeAll()
        componentIdsByEntity.removeAll()
        familyMembersByTraits.removeAll()
    }

    deinit {
        clear()
    }
}

// MARK: - Equatable
extension Nexus: Equatable {
    public static func == (lhs: Nexus, rhs: Nexus) -> Bool {
        return lhs.entityStorage == rhs.entityStorage &&
            lhs.componentIdsByEntity == rhs.componentIdsByEntity &&
            lhs.freeEntities == rhs.freeEntities &&
            lhs.familyMembersByTraits == rhs.familyMembersByTraits &&
            lhs.componentsByType.keys == rhs.componentsByType.keys
        // NOTE: components are not equatable (yet)
    }
}

// MARK: - nexus delegate
extension Nexus {
    internal func notify(_ event: ECSEvent) {
        delegate?.nexusEventOccurred(event)
    }

    internal func report(_ message: String) {
        delegate?.nexusRecoverableErrorOccurred(message)
    }
}

// MARK: - CustomDebugStringConvertible
extension Nexus: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Nexus<Entities:\(numEntities) Components:\(numComponents) Families:\(numFamilies)>"
    }
}
