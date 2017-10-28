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
	public func family(requiresAll allComponents: [Component.Type],
					   excludesAll noneComponents: [Component.Type],
					   needsAtLeastOne oneComponents: [Component.Type] = []) -> Family {
		let traits = FamilyTraitSet(requiresAll: allComponents, excludesAll: noneComponents, needsAtLeastOne: oneComponents)
		return family(with: traits)
	}

	public func family(with traits: FamilyTraitSet) -> Family {
		guard let family: Family = get(family: traits) else {
			return create(family: traits)
		}
		return family
	}

	public func canBecomeMember(_ entity: Entity, in family: Family) -> Bool {
		let entityIdx: EntityIndex = entity.identifier.index
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else {
			assert(false, "no component set defined for entity: \(entity)")
			return false
		}
		// FIXME: may be a bottle neck
		let componentSet: ComponentSet = ComponentSet.init(componentIds)
		return family.traits.isMatch(components: componentSet)
	}

	public func members(of family: Family) -> EntityIdSet {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		return familyMembersByTraitHash[traitHash] ?? [] // FIXME: fail?
	}

	/*public func members(of family: Family) -> LazyMapCollection<LazyFilterCollection<LazyMapCollection<EntityIdSet, Entity?>>, Entity> {
		return members(of: family).lazy.flatMap { self.get(entity: $0) }
	}*/

	public func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

	public func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		// FIXME: this may be costly for many entities in family
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

		// FIXME: this is costly for many entities
		for entity: Entity in entities {
			update(membership: family, for: entity.identifier)
		}

		notify(FamilyCreated(family: traits))
		return family
	}

	// FIXME: remove families?!

	// MARK: - update family membership

	func update(membership family: Family, for entityId: EntityIdentifier) {
		let entityIdx: EntityIndex = entityId.index
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else { return }
		// FIXME: bottle neck
		let componentsSet: ComponentSet = ComponentSet.init(componentIds)
		let isMember: Bool = family.isMember(entityId)
		let isMatch: Bool = family.traits.isMatch(components: componentsSet)
		switch (isMatch, isMember) {
		case (true, false):
			add(to: family, entityId: entityId)
		case (false, true):
			remove(from: family, entityId: entityId)
		default:
			break
		}
	}

	fileprivate func add(to family: Family, entityId: EntityIdentifier) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue

		if familyMembersByTraitHash[traitHash] != nil {
			familyMembersByTraitHash[traitHash]?.insert(entityId)
		} else {
			familyMembersByTraitHash[traitHash] = EntityIdSet(arrayLiteral: entityId)
		}

		notify(FamilyMemberAdded(member: entityId, to: family.traits))
	}

	fileprivate func remove(from family: Family, entityId: EntityIdentifier) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue

		guard let removed: EntityIdentifier = familyMembersByTraitHash[traitHash]?.remove(entityId) else {
			assert(false, "removing entity id \(entityId) that is not in family \(family)")
			report("removing entity id \(entityId) that is not in family \(family)")
			return
		}

		notify(FamilyMemberRemoved(member: removed, from: family.traits))
	}

}
