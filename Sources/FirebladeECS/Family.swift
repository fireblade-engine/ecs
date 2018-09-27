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

	// TODO: implemenet
	// a) define sort order of entities
	// b) define read/write access
	// c) set size and storage constraints
    // d) conform to collection
    // e) consider family to be a struct
	// f) iterate family A and family B in pairs - i.e. zip
	// g) pair-wise comparison inside families or between families

	internal init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.nexus = nexus
		self.traits = traits
		defer {
			self.nexus?.onFamilyInit(traits: self.traits)
		}
	}

	deinit {
		nexus?.onFamilyDeinit(traits: traits)
	}

	public final var memberIds: UniformEntityIdentifiers {
		return nexus?.members(withFamilyTraits: traits) ?? UniformEntityIdentifiers()
	}

	public final var count: Int {
		return nexus?.members(withFamilyTraits: traits)?.count ?? 0
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
        return lhs.traits == rhs.traits && lhs.nexus == rhs.nexus
    }

}
