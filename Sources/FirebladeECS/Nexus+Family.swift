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
		let traits = FamilyTraitSet(requiresAll: allComponents, excludesAll: noneComponents, needsAtLeastOne: oneComponents)
		return family(with: traits)
	}

	func family(with traits: FamilyTraitSet) -> Family {
		guard let family: Family = get(family: traits) else {
			return create(family: traits)
		}
		return family
	}

	func canBecomeMember(_ entity: Entity, in family: Family) -> Bool {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else {
			assert(false, "no component set defined for entity: \(entity)")
			return false
		}
		let componentSet: ComponentSet = ComponentSet(componentIds)
		return family.traits.isMatch(components: componentSet)
	}

	func members(of family: Family) -> UniformEntityIdentifiers {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		return members(of: traitHash)
	}

	func members(of traitHash: FamilyTraitSetHash) -> UniformEntityIdentifiers {
		// FIXME: we may fail here if this is empty
		return familyMembersByTraitHash[traitHash] ?? UniformEntityIdentifiers()
	}

	func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

	func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		guard let members: UniformEntityIdentifiers = familyMembersByTraitHash[traitHash] else {
			return false
		}
		return members.has(entityId.index)
	}

}

// MARK: - internal extensions
extension Nexus {

	/// will be called on family init defer
	func onFamilyInit(family: Family) {
		// FIXME: this is costly for many entities
		for entity: Entity in entityStorage {
			update(membership: family, for: entity.identifier)
		}
	}

	func onFamilyDeinit(traitHash: FamilyTraitSetHash) {
		for member in members(of: traitHash) {
			remove(from: traitHash, entityId: member, entityIdx: member.index)
		}
	}

	func update(membership family: Family, for entityId: EntityIdentifier) {
		let entityIdx: EntityIndex = entityId.index
		let traits: FamilyTraitSet = family.traits
		let traitHash: FamilyTraitSetHash = traits.hashValue
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else {
			return
		}

		let is_Member: Bool = isMember(entityId, in: family)
		if !isValid(entity: entityId) && is_Member {
			remove(from: traitHash, entityId: entityId, entityIdx: entityIdx)
			return
		}

		let componentsSet: ComponentSet = ComponentSet(componentIds)
		let isMatch: Bool = traits.isMatch(components: componentsSet)
		switch (isMatch, is_Member) {
		case (true, false):
			add(to: traitHash, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberAdded(member: entityId, toFamily: traits))
		case (false, true):
			remove(from: traitHash, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberRemoved(member: entityId, from: traits))
		default:
			break
		}
	}

}

// MARK: - fileprivate extensions
private extension Nexus {

	func get(family traits: FamilyTraitSet) -> Family? {
		let traitHash: FamilyTraitSetHash = traits.hashValue
		return familiesByTraitHash[traitHash]
	}

	func create(family traits: FamilyTraitSet) -> Family {
		let traitHash: FamilyTraitSetHash = traits.hashValue
		let family = Family(self, traits: traits)
		let replaced = familiesByTraitHash.updateValue(family, forKey: traitHash)
		assert(replaced == nil, "Family with exact trait hash already exists: \(traitHash)")
		notify(FamilyCreated(family: traits))
		return family
	}

	func calculateTraitEntityIdHash(traitHash: FamilyTraitSetHash, entityIdx: EntityIndex) -> TraitEntityIdHash {
		return hash(combine: traitHash, entityIdx)
	}
	func add(to traitHash: FamilyTraitSetHash, entityId: EntityIdentifier, entityIdx: EntityIndex) {
		if familyMembersByTraitHash[traitHash] == nil {
			familyMembersByTraitHash[traitHash] = UniformEntityIdentifiers()
		}
		familyMembersByTraitHash[traitHash]?.add(entityId, at: entityIdx)
	}

	func remove(from traitHash: FamilyTraitSetHash, entityId: EntityIdentifier, entityIdx: EntityIndex) {
		familyMembersByTraitHash[traitHash]?.remove(at: entityIdx)
	}
}
