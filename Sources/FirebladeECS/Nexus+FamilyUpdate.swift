//
//  Nexus+FamilyUpdate.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

extension Nexus {
    /// will be called on family init
    final func onFamilyInit(traits: FamilyTraitSet) {
        guard familyMembersByTraits[traits] == nil else {
            return
        }

        familyMembersByTraits[traits] = UniformEntityIdentifiers()
        update(familyMembership: traits)
    }

    final func update(familyMembership traits: FamilyTraitSet) {
        // FIXME: iterating all entities is costly for many entities
        for entity: Entity in entityStorage {
            update(membership: traits, for: entity.identifier)
        }
    }

    final func update(familyMembership entityId: EntityIdentifier) {
        // FIXME: iterating all families is costly for many families
        for (traits, _) in familyMembersByTraits {
            update(membership: traits, for: entityId)
        }
    }

    final func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
        let entityIdx: EntityIndex = entityId.index
        guard let componentIds: SparseComponentIdentifierSet = componentIdsByEntity[entityIdx] else {
            // no components - so skip
            return
        }

        let isMember: Bool = self.isMember(entity: entityId, inFamilyWithTraits: traits)
        if !exists(entity: entityId) && isMember {
            remove(entityWithId: entityId, andIndex: entityIdx, fromFamilyWithTraits: traits)
            return
        }

        // TODO: get rid of set creation for comparison by conforming UnorderedSparseSet to SetAlgebra
        let componentsSet = ComponentSet(componentIds)
        let isMatch: Bool = traits.isMatch(components: componentsSet)

        switch (isMatch, isMember) {
        case (true, false):
            add(entityWithId: entityId, andIndex: entityIdx, toFamilyWithTraits: traits)
            notify(FamilyMemberAdded(member: entityId, toFamily: traits))
            return

        case (false, true):
            remove(entityWithId: entityId, andIndex: entityIdx, fromFamilyWithTraits: traits)
            notify(FamilyMemberRemoved(member: entityId, from: traits))
            return

        default:
            return
        }
    }

    final func add(entityWithId entityId: EntityIdentifier, andIndex entityIdx: EntityIndex, toFamilyWithTraits traits: FamilyTraitSet) {
        precondition(familyMembersByTraits[traits] != nil)
        familyMembersByTraits[traits].unsafelyUnwrapped.insert(entityId, at: entityIdx)
    }

    final func remove(entityWithId entityId: EntityIdentifier, andIndex entityIdx: EntityIndex, fromFamilyWithTraits traits: FamilyTraitSet) {
        precondition(familyMembersByTraits[traits] != nil)
        familyMembersByTraits[traits].unsafelyUnwrapped.remove(at: entityIdx)
    }
}
