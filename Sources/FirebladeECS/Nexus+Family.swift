//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// The total number of families managed by the Nexus.
    public final var numFamilies: Int {
        familyMembersByTraits.keys.count
    }

    /// Checks if an entity can become a member of a family defined by traits.
    /// - Parameters:
    ///   - entity: The entity to check.
    ///   - traits: The family traits.
    /// - Returns: `true` if the entity matches the traits.
    /// - Complexity: O(T) where T is the number of traits in the family.
    public func canBecomeMember(_ entity: Entity, in traits: FamilyTraitSet) -> Bool {
        guard let componentIds = componentIdsByEntity[entity.identifier] else {
            return false
        }
        return traits.isMatch(components: componentIds)
    }

    /// Retrieves the members of a family defined by traits.
    /// - Parameter traits: The family traits.
    /// - Returns: A set of entity identifiers.
    /// - Complexity: O(1)
    public func members(withFamilyTraits traits: FamilyTraitSet) -> UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier> {
        familyMembersByTraits[traits] ?? UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>()
    }

    /// Checks if an entity is a member of a family.
    /// - Parameters:
    ///   - entity: The entity to check.
    ///   - family: The family traits.
    /// - Returns: `true` if the entity is a member.
    /// - Complexity: O(1)
    public func isMember(_ entity: Entity, in family: FamilyTraitSet) -> Bool {
        isMember(entity.identifier, in: family)
    }

    /// Checks if an entity identifier is a member of a family.
    /// - Parameters:
    ///   - entityId: The entity identifier.
    ///   - family: The family traits.
    /// - Returns: `true` if the entity identifier is a member.
    /// - Complexity: O(1)
    public func isMember(_ entityId: EntityIdentifier, in family: FamilyTraitSet) -> Bool {
        isMember(entity: entityId, inFamilyWithTraits: family)
    }

    /// Checks if an entity identifier is a member of a family defined by traits.
    /// - Parameters:
    ///   - entityId: The entity identifier.
    ///   - traits: The family traits.
    /// - Returns: `true` if the entity identifier is a member.
    /// - Complexity: O(1)
    public func isMember(entity entityId: EntityIdentifier, inFamilyWithTraits traits: FamilyTraitSet) -> Bool {
        members(withFamilyTraits: traits).contains(entityId.id)
    }
}
