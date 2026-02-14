//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// The total number of families managed by the Nexus.
    /// - Complexity: O(1)
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

    /// Create a family of entities (aka members) having 1 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 1 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requires: Comp1.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp: Component type required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Complexity: O(1) for existing families, O(N) where N is the number of entities for new families.
    /// - Returns: The family of entities having 1 required components each.
    public func family<Comp: Component>(
        requires comp: Comp.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family<Comp> {
        Family<Comp>(
            nexus: self,
            requiresAll: comp,
            excludesAll: excludedComponents
        )
    }

    /// Create a family of entities (aka members) having the required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1: Comp1, comp2: Comp2) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - componentTypes: Component types required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Complexity: O(1) for existing families, O(N) where N is the number of entities for new families.
    /// - Returns: The family of entities having the required components.
    public func family<each C: Component>(
        requiresAll componentTypes: repeat (each C).Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family<repeat each C> {
        Family(
            nexus: self,
            requiresAll: repeat each componentTypes,
            excludesAll: excludedComponents
        )
    }
}
