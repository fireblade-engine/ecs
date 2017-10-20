//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	/// Gets or creates (new) family with given traits.
	///
	/// - Parameters:
	///   - allComponents: all component types are required in this family.
	///   - noneComponents: none component type may appear in this family.
	///   - oneComponents: at least one of component types must appear in this family.
	/// - Returns: family with given traits.
	public func family(requiresAll allComponents: [Component.Type], excludesAll noneComponents: [Component.Type], needsAtLeastOne oneComponents: [Component.Type] = []) -> Family {

		let traits = FamilyTraitSet(requiresAll: allComponents, excludesAll: noneComponents, needsAtLeastOne: oneComponents)

		guard let family: Family = get(family: traits) else {
			return create(family: traits)
		}
		return family
	}

	public func canBecomeMember(_ entity: Entity, in family: Family) -> Bool {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentSet: ComponentSet = componentIdsSetByEntity[entityIdx] else {
			assert(false, "no component set defined for entity: \(entity)")
			return false
		}
		return family.traits.isMatch(components: componentSet)
	}

	public func members(of family: Family) -> EntitySet {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		return familyMembersByTraitHash[traitHash] ?? [] // FIXME: fail?
	}

	public func isMember(_ entity: Entity, in family: Family) -> Bool {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		let entityId = entity.identifier
		return familyMembersByTraitHash[traitHash]?.contains(entityId) ?? false
	}

	fileprivate func get(family traits: FamilyTraitSet) -> Family? {
		let traitHash: FamilyTraitSetHash = traits.hashValue
		return familiyByTraitHash[traitHash]
	}

	fileprivate func create(family traits: FamilyTraitSet) -> Family {
		let traitHash: FamilyTraitSetHash = traits.hashValue
		let family = Family(self, traits: traits)
		let replaced = familiyByTraitHash.updateValue(family, forKey: traitHash)
		assert(replaced == nil, "Family with exact trait hash already exists: \(traitHash)")
		notify(FamilyCreated(family: traits))
		// FIXME: update memberships for prior entites
		return family
	}

	// FIXME: remove families?!

	// MARK: - update family membership

	func update(membership family: Family, for entity: Entity) {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentsSet: ComponentSet = componentIdsSetByEntity[entityIdx] else { return }
		let isMatch: Bool = family.traits.isMatch(components: componentsSet)
		switch isMatch {
		case true:
			add(to: family, entity: entity)
		case false:
			remove(from: family, entity: entity)
		}
	}

	fileprivate func add(to family: Family, entity: Entity) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		let entityId: EntityIdentifier = entity.identifier
		if familyMembersByTraitHash[traitHash] != nil {
			let (inserted, _) = familyMembersByTraitHash[traitHash]!.insert(entityId)
			assert(inserted, "entity with id \(entityId) already in family")
		} else {
			familyMembersByTraitHash[traitHash] = EntitySet(minimumCapacity: 2)
			familyMembersByTraitHash[traitHash]!.insert(entityId)
		}

		notify(FamilyMemberAdded(member: entityId, to: family.traits))
	}

	fileprivate func remove(from family: Family, entity: Entity) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		let entityId: EntityIdentifier = entity.identifier

		guard let removed = familyMembersByTraitHash[traitHash]?.remove(entityId) else {
			assert(false, "removing entity id \(entityId) that is not in family \(family)")
			report("removing entity id \(entityId) that is not in family \(family)")
			return
		}

		notify(FamilyMemberRemoved(member: removed, from: family.traits))
	}

}
