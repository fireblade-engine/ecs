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

        familyMembersByTraits[traits] = UnorderedSparseSet<EntityIdentifier>()
        update(familyMembership: traits)
    }

    final func update(familyMembership traits: FamilyTraitSet) {
        // FIXME: iterating all entities is costly for many entities
        var iter = entityStorage.makeIterator()
        while let entity = iter.next() {
            update(membership: traits, for: entity.identifier)
        }
    }

    final func update(familyMembership entityId: EntityIdentifier) {
        // FIXME: iterating all families is costly for many families
        var iter = familyMembersByTraits.keys.makeIterator()
        while let traits = iter.next() {
            update(membership: traits, for: entityId)
        }
    }

    final func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
        guard let componentIds = componentIdsByEntity[entityId] else {
            // no components - so skip
            return
        }

        let isMember: Bool = self.isMember(entity: entityId, inFamilyWithTraits: traits)
        if !exists(entity: entityId) && isMember {
            remove(entityWithId: entityId, fromFamilyWithTraits: traits)
            return
        }

        let isMatch: Bool = traits.isMatch(components: componentIds)

        switch (isMatch, isMember) {
        case (true, false):
            add(entityWithId: entityId, toFamilyWithTraits: traits)
            delegate?.nexusEvent(FamilyMemberAdded(member: entityId, toFamily: traits))
            return

        case (false, true):
            remove(entityWithId: entityId, fromFamilyWithTraits: traits)
            delegate?.nexusEvent(FamilyMemberRemoved(member: entityId, from: traits))
            return

        default:
            return
        }
    }

    final func add(entityWithId entityId: EntityIdentifier, toFamilyWithTraits traits: FamilyTraitSet) {
        precondition(familyMembersByTraits[traits] != nil)
        familyMembersByTraits[traits]!.insert(entityId, at: entityId.id)
    }

    final func remove(entityWithId entityId: EntityIdentifier, fromFamilyWithTraits traits: FamilyTraitSet) {
        precondition(familyMembersByTraits[traits] != nil)
        familyMembersByTraits[traits]!.remove(at: entityId.id)
    }
}
