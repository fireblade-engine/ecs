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

	/// Gets or creates (new) family with given traits.
	///
	/// - Parameters:
	///   - allComponents: all component types are required in this family.
	///   - noneComponents: none component type may appear in this family.
	///   - oneComponents: at least one of component types must appear in this family.
	/// - Returns: family with given traits.
	func family(requiresAll allComponents: [Component.Type], excludesAll noneComponents: [Component.Type], needsAtLeastOne oneComponents: [Component.Type] = []) -> Family {
        let traits: FamilyTraitSet = FamilyTraitSet(requiresAll: allComponents, excludesAll: noneComponents, needsAtLeastOne: oneComponents)
		return family(with: traits)
	}

	func family(with traits: FamilyTraitSet) -> Family {
        return create(family: traits)
	}

	func canBecomeMember(_ entity: Entity, in family: Family) -> Bool {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentIds: SparseComponentIdentifierSet = componentIdsByEntity[entityIdx] else {
			assertionFailure("no component set defined for entity: \(entity)")
			return false
		}
		let componentSet: ComponentSet = ComponentSet(componentIds)
		return family.traits.isMatch(components: componentSet)
	}

	func members(withFamilyTraits traits: FamilyTraitSet) -> UniformEntityIdentifiers? {
		return familyMembersByTraits[traits]
	}

	func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

    func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
        return isMember(entity: entityId, inFamilyWithTraits: family.traits)
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

	func update(familyMembership entityId: EntityIdentifier) {
		// FIXME: iterating all families is costly for many families
        familyMembersByTraits.forEach { familyTraits, _ in update(membership: familyTraits, for: entityId) }

	}

    enum UpdateState {
        case noComponents(id: EntityIdentifier, traits: FamilyTraitSet)
        case added(id: EntityIdentifier, traits: FamilyTraitSet)
        case removedDeleted(id: EntityIdentifier, traits: FamilyTraitSet)
        case removed(id: EntityIdentifier, traits: FamilyTraitSet)
        case unchanged(id: EntityIdentifier, traits: FamilyTraitSet)
    }

	func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
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
		let componentsSet: ComponentSet = ComponentSet(componentIds)
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
    func onFamilyInit(traits: FamilyTraitSet) {

        if familyMembersByTraits[traits] == nil {
            familyMembersByTraits[traits] = UniformEntityIdentifiers()
        }

        // FIXME: this is costly for many entities
        for entity: Entity in entityStorage {
            update(membership: traits, for: entity.identifier)
        }
    }

    func onFamilyDeinit(traits: FamilyTraitSet) {
        // nothing todo here
    }

}

// MARK: - fileprivate extensions
private extension Nexus {

	final func get(family traits: FamilyTraitSet) -> Family? {
        return create(family: traits)
	}

	final func create(family traits: FamilyTraitSet) -> Family {
        let family: Family = Family(self, traits: traits)
		return family
	}

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
