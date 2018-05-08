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

	// TODO: add family configuration feature
	// a) define sort order of entities
	// b) define read/write access
	// c) set size and storage constraints
    // d) conform to collection

	// TODO: family unions
	// a) iterate family A and family B in pairs - i.e. zip
	// b) pair-wise comparison inside families or between families

	init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.nexus = nexus
		self.traits = traits
		defer {
			self.nexus?.onFamilyInit(family: self)
		}
	}

	deinit {
		let hash: FamilyTraitSetHash = traits.hashValue
		nexus?.onFamilyDeinit(traitHash: hash)
	}

	var memberIds: UniformEntityIdentifiers {
		return nexus?.members(of: self) ?? UniformEntityIdentifiers()
	}
}

public extension Family {

	var count: Int {
		return nexus?.members(of: self)?.count ?? 0
	}

	final func canBecomeMember(_ entity: Entity) -> Bool {
		return nexus?.canBecomeMember(entity, in: self) ?? false
	}

	final func isMember(_ entity: Entity) -> Bool {
		return nexus?.isMember(entity, in: self) ?? false
	}

	final func isMember(_ entityId: EntityIdentifier) -> Bool {
		return nexus?.isMember(entityId, in: self) ?? false
	}

}
