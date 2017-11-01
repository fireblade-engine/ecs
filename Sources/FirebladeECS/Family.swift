//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {
	internal var nexus: Nexus
	// members of this Family must conform to these traits
	public let traits: FamilyTraitSet

	internal init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.nexus = nexus
		self.traits = traits

	}

	deinit {

	}
}

extension Family {

	public var count: Int {
		return nexus.members(of: self).count
	}

	public final func canBecomeMember(_ entity: Entity) -> Bool {
		return nexus.canBecomeMember(entity, in: self)
	}

	public final func isMember(_ entity: Entity) -> Bool {
		return nexus.isMember(entity, in: self)
	}

	public final func isMember(_ entityId: EntityIdentifier) -> Bool {
		return nexus.isMember(entityId, in: self)
	}

	internal var memberIds: UniformEntityIdentifiers {
		return nexus.members(of: self)
	}
}
