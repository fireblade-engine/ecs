//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

public extension Nexus {

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

	func members(of traits: FamilyTraitSet) -> UniformEntityIdentifiers? {
		return familyMembersByTraits[traits]
	}

	func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

    func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
        return isMember(entityId, in: family.traits)
    }

	func isMember(_ entityId: EntityIdentifier, in traits: FamilyTraitSet) -> Bool {
		guard let members: UniformEntityIdentifiers = members(of: traits) else {
			return false
		}
		return members.contains(entityId.index)
	}

}

// MARK: - internal extensions
extension Nexus {

	/// will be called on family init defer
	func onFamilyInit(traits: FamilyTraitSet) {
        createTraitsIfNeccessary(traits: traits)

		// FIXME: this is costly for many entities
		for entity: Entity in entityStorage {
			update(membership: traits, for: entity.identifier)
		}
	}

	func onFamilyDeinit(traits: FamilyTraitSet) {
		guard let members: UniformEntityIdentifiers = members(of: traits) else {
			return
		}

        for member: EntityIdentifier in members {
			remove(from: traits, entityId: member, entityIdx: member.index)
		}
	}

	func update(familyMembership entityId: EntityIdentifier) {
		// FIXME: iterating all families is costly for many families
        for (familyTraits, _) in familyMembersByTraits {
            update(membership: familyTraits, for: entityId)
		}
	}

	func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
		let entityIdx: EntityIndex = entityId.index
		guard let componentIds: SparseComponentIdentifierSet = componentIdsByEntity[entityIdx] else {
			return
		}

		let isMember: Bool = self.isMember(entityId, in: traits)
		if !has(entity: entityId) && isMember {
			remove(from: traits, entityId: entityId, entityIdx: entityIdx)
			return
		}

		let componentsSet: ComponentSet = ComponentSet(componentIds)
		let isMatch: Bool = traits.isMatch(components: componentsSet)
		switch (isMatch, isMember) {
		case (true, false):
			add(to: traits, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberAdded(member: entityId, toFamily: traits))
		case (false, true):
			remove(from: traits, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberRemoved(member: entityId, from: traits))
		default:
			break
		}
	}

}

// MARK: - fileprivate extensions
private extension Nexus {

	func get(family traits: FamilyTraitSet) -> Family? {
        return create(family: traits)
	}

	func create(family traits: FamilyTraitSet) -> Family {
        let family: Family = Family(self, traits: traits)
		return family
	}

    func createTraitsIfNeccessary(traits: FamilyTraitSet) {
        guard familyMembersByTraits[traits] == nil else {
            return
        }
        familyMembersByTraits[traits] = UniformEntityIdentifiers()
    }

	func calculateTraitEntityIdHash(traitHash: FamilyTraitSetHash, entityIdx: EntityIndex) -> TraitEntityIdHash {
		return hash(combine: traitHash, entityIdx)
	}

	func add(to traits: FamilyTraitSet, entityId: EntityIdentifier, entityIdx: EntityIndex) {
        createTraitsIfNeccessary(traits: traits)
		familyMembersByTraits[traits]?.insert(entityId, at: entityIdx)
	}

	func remove(from traits: FamilyTraitSet, entityId: EntityIdentifier, entityIdx: EntityIndex) {
		familyMembersByTraits[traits]?.remove(at: entityIdx)
	}
}
