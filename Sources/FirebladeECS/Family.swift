//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {
	weak var nexus: Nexus?
	// members of this Family must conform to these traits
	public let traits: FamilyTraitSet

	init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.nexus = nexus
		self.traits = traits
		defer {
			nexus.onFamilyInit(family: self)
		}
	}

	deinit {
		let hash: FamilyTraitSetHash = traits.hashValue
		nexus?.onFamilyDeinit(traitHash: hash)
	}
}

extension Family {

	public var count: Int {
		return nexus?.members(of: self).count ?? 0
	}

	public final func canBecomeMember(_ entity: Entity) -> Bool {
		return nexus?.canBecomeMember(entity, in: self) ?? false
	}

	public final func isMember(_ entity: Entity) -> Bool {
		return nexus?.isMember(entity, in: self) ?? false
	}

	public final func isMember(_ entityId: EntityIdentifier) -> Bool {
		return nexus?.isMember(entityId, in: self) ?? false
	}

	var memberIds: UniformEntityIdentifiers {
		return nexus!.members(of: self)
	}
}
