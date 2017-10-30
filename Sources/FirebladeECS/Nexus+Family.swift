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

	public func members(of family: Family) -> [EntityIdentifier] {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		return familyMembersByTraitHash[traitHash] ?? [] // FIXME: fail?
	}

	public func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

	public func isMember(byHash traitSetEntityIdHash: TraitEntityIdHash) -> Bool {
		return familyContainsEntityId[traitSetEntityIdHash] ?? false
	}

	public func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		// FIXME: this is costly!
		guard let members: [EntityIdentifier] = familyMembersByTraitHash[traitHash] else { return false }
		return members.contains(entityId)
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
		for entity: Entity in entityStorage {
			update(membership: family, for: entity.identifier)
		}

		notify(FamilyCreated(family: traits))
		return family
	}

	// FIXME: remove families?!

	// MARK: - update family membership

	fileprivate func calculateTraitEntityIdHash(traitHash: FamilyTraitSetHash, entityIdx: EntityIndex) -> TraitEntityIdHash {
		return hash(combine: traitHash, entityIdx)
	}

	func update(membership family: Family, for entityId: EntityIdentifier) {
		let entityIdx: EntityIndex = entityId.index
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else { return }

		let trash: TraitEntityIdHash = calculateTraitEntityIdHash(traitHash: traitHash, entityIdx: entityIdx)
		let is_Member: Bool = isMember(byHash: trash)

		let componentsSet: ComponentSet = ComponentSet.init(componentIds)
		let isMatch: Bool = family.traits.isMatch(components: componentsSet)
		switch (isMatch, is_Member) {
		case (true, false):
			add(to: family, entityId: entityId, with: trash)
		case (false, true):
			remove(from: family, entityId: entityId, with: trash)
		default:
			break
		}
	}

	fileprivate func add(to family: Family, entityId: EntityIdentifier, with traitEntityIdHash: TraitEntityIdHash) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		if familyMembersByTraitHash[traitHash] != nil {
			// here we already checked if entity is a member
			familyMembersByTraitHash[traitHash]!.append(entityId)
		} else {
			familyMembersByTraitHash[traitHash] = [EntityIdentifier].init(arrayLiteral: entityId)
			familyMembersByTraitHash.reserveCapacity(4096)
		}

		familyContainsEntityId[traitEntityIdHash] = true

		notify(FamilyMemberAdded(member: entityId, to: family.traits))
	}

	fileprivate func remove(from family: Family, entityId: EntityIdentifier, with traitEntityIdHash: TraitEntityIdHash) {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue

		// FIXME: index of is not cheep
		guard let indexInFamily = familyMembersByTraitHash[traitHash]?.index(of: entityId) else {
			assert(false, "removing entity id \(entityId) that is not in family \(family)")
			report("removing entity id \(entityId) that is not in family \(family)")
			return
		}

		let removed: EntityIdentifier = familyMembersByTraitHash[traitHash]!.remove(at: indexInFamily)
		familyContainsEntityId[traitEntityIdHash] = false
		notify(FamilyMemberRemoved(member: removed, from: family.traits))
	}

}
