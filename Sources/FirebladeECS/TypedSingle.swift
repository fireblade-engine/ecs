//
//  TypedSingle.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

public struct TypedSingle1<A>: Equatable where A: Component {
    public let nexus: Nexus
    public let traits: FamilyTraitSet

    public init(_ nexus: Nexus, requires compA: A.Type, excludesAll: [Component.Type]) {
        self.nexus = nexus
        traits = FamilyTraitSet(requiresAll: [compA], excludesAll: excludesAll)
        nexus.onFamilyInit(traits: traits)
    }

    @inlinable public var entityId: EntityIdentifier? {
        guard let members = nexus.members(withFamilyTraits: traits) else {
            return nil
        }
        guard let singleMemberId: EntityIdentifier = members.first else {
            return nil
        }
        return singleMemberId
    }

    @inlinable public var entity: Entity? {
        guard let entityId = entityId else {
            return nil
        }
        return nexus.get(entity: entityId)
    }

    @inlinable public var component: A? {
        return entity?.get(component: A.self)
    }
}
