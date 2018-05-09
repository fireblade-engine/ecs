//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family: Equatable {

	public weak var nexus: Nexus?
	// members of this Family must conform to these traits
	public let traits: FamilyTraitSet

	// TODO: add family configuration feature
	// a) define sort order of entities
	// b) define read/write access
	// c) set size and storage constraints
    // d) conform to collection
    // e) consider family to be a struct

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

	public final var memberIds: UniformEntityIdentifiers {
		return nexus?.members(of: self) ?? UniformEntityIdentifiers()
	}

	public final var count: Int {
		return nexus?.members(of: self)?.count ?? 0
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

    // MARK: Equatable
    public static func == (lhs: Family, rhs: Family) -> Bool {
        // TODO: maybe this is not enough for equality
        return lhs.traits == rhs.traits && lhs.nexus == rhs.nexus
    }

}
