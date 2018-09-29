//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

public extension Nexus {

    final var numFamilies: Int {
        return familyMembersByTraits.keys.count
    }

	func canBecomeMember(_ entity: Entity, in traits: FamilyTraitSet) -> Bool {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentIds: SparseComponentIdentifierSet = componentIdsByEntity[entityIdx] else {
			assertionFailure("no component set defined for entity: \(entity)")
			return false
		}
		let componentSet = ComponentSet(componentIds)
		return traits.isMatch(components: componentSet)
	}

	func members(withFamilyTraits traits: FamilyTraitSet) -> UniformEntityIdentifiers? {
		return familyMembersByTraits[traits]
	}

	func isMember(_ entity: Entity, in family: FamilyTraitSet) -> Bool {
		return isMember(entity.identifier, in: family)
	}

    func isMember(_ entityId: EntityIdentifier, in family: FamilyTraitSet) -> Bool {
        return isMember(entity: entityId, inFamilyWithTraits: family)
    }

	func isMember(entity entityId: EntityIdentifier, inFamilyWithTraits traits: FamilyTraitSet) -> Bool {
		guard let members: UniformEntityIdentifiers = members(withFamilyTraits: traits) else {
			return false
		}
		return members.contains(entityId.index)
	}

}

// MARK: - internal extensions
extension Nexus {

	internal func update(familyMembership entityId: EntityIdentifier) {
		// FIXME: iterating all families is costly for many families
        familyMembersByTraits.forEach { familyTraits, _ in update(membership: familyTraits, for: entityId) }

	}

    internal enum UpdateState {
        case noComponents(id: EntityIdentifier, traits: FamilyTraitSet)
        case added(id: EntityIdentifier, traits: FamilyTraitSet)
        case removedDeleted(id: EntityIdentifier, traits: FamilyTraitSet)
        case removed(id: EntityIdentifier, traits: FamilyTraitSet)
        case unchanged(id: EntityIdentifier, traits: FamilyTraitSet)
    }

	internal func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
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

        // TODO: get rid of set creation for comparison
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

    /// will be called on family init defer
    internal func onFamilyInit(traits: FamilyTraitSet) {

        if familyMembersByTraits[traits] == nil {
            familyMembersByTraits[traits] = UniformEntityIdentifiers()
        }

        // FIXME: this is costly for many entities
        for entity: Entity in entityStorage {
            update(membership: traits, for: entity.identifier)
        }
    }

    internal func onFamilyDeinit(traits: FamilyTraitSet) {
        // nothing todo here
    }

}

// MARK: - fileprivate extensions
private extension Nexus {

	final func calculateTraitEntityIdHash(traitHash: FamilyTraitSetHash, entityIdx: EntityIndex) -> TraitEntityIdHash {
		return hash(combine: traitHash, entityIdx)
	}

	final func add(entityWithId entityId: EntityIdentifier, andIndex entityIdx: EntityIndex, toFamilyWithTraits traits: FamilyTraitSet) {
        if familyMembersByTraits[traits] == nil {
            familyMembersByTraits[traits] = UniformEntityIdentifiers()
        }
		familyMembersByTraits[traits]?.insert(entityId, at: entityIdx)
	}

	final func remove(entityWithId entityId: EntityIdentifier, andIndex entityIdx: EntityIndex, fromFamilyWithTraits traits: FamilyTraitSet) {
		familyMembersByTraits[traits]?.remove(at: entityIdx)
	}
}
