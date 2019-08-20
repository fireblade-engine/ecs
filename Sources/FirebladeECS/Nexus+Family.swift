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
		guard let componentIds = componentIdsByEntity[entity.identifier] else {
			assertionFailure("no component set defined for entity: \(entity)")
			return false
		}
		return traits.isMatch(components: componentIds)
	}

	func members(withFamilyTraits traits: FamilyTraitSet) -> UnorderedSparseSet<EntityIdentifier> {
		return familyMembersByTraits[traits] ?? UnorderedSparseSet<EntityIdentifier>()
	}

	func isMember(_ entity: Entity, in family: FamilyTraitSet) -> Bool {
		return isMember(entity.identifier, in: family)
	}

    func isMember(_ entityId: EntityIdentifier, in family: FamilyTraitSet) -> Bool {
        return isMember(entity: entityId, inFamilyWithTraits: family)
    }

	func isMember(entity entityId: EntityIdentifier, inFamilyWithTraits traits: FamilyTraitSet) -> Bool {
		return members(withFamilyTraits: traits).contains(entityId.index)
	}
}
