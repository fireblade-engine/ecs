//
//  Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: - family
public final class Family {
	internal unowned var delegate: Nexus
	// members of this Family must conform to these traits
	public let traits: FamilyTraitSet

	internal init(_ nexus: Nexus, traits: FamilyTraitSet) {
		self.delegate = nexus
		self.traits = traits
		defer {
			nexus.onFamilyCreated(family: self)
		}
	}

	deinit {
		delegate.onFamilyRemove(family: self)
	}
}

extension Family {

	public var count: Int {
		return delegate.members(of: self).count
	}

	public final func canBecomeMember(_ entity: Entity) -> Bool {
		return delegate.canBecomeMember(entity, in: self)
	}

	public final func isMember(_ entity: Entity) -> Bool {
		return delegate.isMember(entity, in: self)
	}

	public final func isMember(_ entityId: EntityIdentifier) -> Bool {
		return delegate.isMember(entityId, in: self)
	}

	internal var memberIds: UniformEntityIdentifiers {
		return delegate.members(of: self)
	}
}
