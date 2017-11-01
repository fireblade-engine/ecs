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

	public func members(of family: Family) -> UniformEntityIdentifiers {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		return familyMembersByTraitHash[traitHash] ?? UniformEntityIdentifiers() // FIXME: fail?
	}

	public func isMember(_ entity: Entity, in family: Family) -> Bool {
		return isMember(entity.identifier, in: family)
	}

	public func isMember(_ entityId: EntityIdentifier, in family: Family) -> Bool {
		let traitHash: FamilyTraitSetHash = family.traits.hashValue
		guard let members: UniformEntityIdentifiers = familyMembersByTraitHash[traitHash] else { return false }
		return members.has(entityId.index)
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
		let traits: FamilyTraitSet = family.traits
		let traitHash: FamilyTraitSetHash = traits.hashValue
		guard let componentIds: ComponentIdentifiers = componentIdsByEntity[entityIdx] else { return }

		let is_Member: Bool = isMember(entityId, in: family)

		let componentsSet: ComponentSet = ComponentSet.init(componentIds)
		let isMatch: Bool = traits.isMatch(components: componentsSet)
		switch (isMatch, is_Member) {
		case (true, false):
			add(to: traitHash, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberAdded(member: entityId, to: traits))
		case (false, true):
			remove(from: traitHash, entityId: entityId, entityIdx: entityIdx)
			notify(FamilyMemberRemoved(member: entityId, from: traits))
		default:
			break
		}
	}

	fileprivate func add(to traitHash: FamilyTraitSetHash, entityId: EntityIdentifier, entityIdx: EntityIndex) {
		if familyMembersByTraitHash[traitHash] == nil {
			familyMembersByTraitHash[traitHash] = UniformEntityIdentifiers()
		}
		familyMembersByTraitHash[traitHash]!.add(entityId, at: entityIdx)
	}

	fileprivate func remove(from traitHash: FamilyTraitSetHash, entityId: EntityIdentifier, entityIdx: EntityIndex) {
		familyMembersByTraitHash[traitHash]?.remove(at: entityIdx)
	}

}
