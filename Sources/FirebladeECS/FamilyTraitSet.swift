//
//  FamilyTraitSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

/// A set of component traits that defines a family.
///
/// A family is defined by a set of required component types and a set of excluded component types.
public struct FamilyTraitSet {
    /// The set of component identifiers that an entity must have to be part of the family.
    public let requiresAll: Set<ComponentIdentifier>

    /// The set of component identifiers that an entity must NOT have to be part of the family.
    public let excludesAll: Set<ComponentIdentifier>

    /// The hash value of the trait set.
    public let setHash: Int

    /// Initializes a new family trait set.
    /// - Parameters:
    ///   - requiresAll: The component types required for membership.
    ///   - excludesAll: The component types excluded from membership.
    public init(requiresAll: [Component.Type], excludesAll: [Component.Type]) {
        let requiresAll = Set<ComponentIdentifier>(requiresAll.map { $0.identifier })
        let excludesAll = Set<ComponentIdentifier>(excludesAll.map { $0.identifier })

        assert(FamilyTraitSet.isValid(requiresAll: requiresAll, excludesAll: excludesAll), "invalid family trait created - requiresAll: \(requiresAll), excludesAll: \(excludesAll)")

        self.requiresAll = requiresAll
        self.excludesAll = excludesAll
        setHash = FirebladeECS.hash(combine: [requiresAll, excludesAll])
    }

    /// Checks if a set of components matches the family traits.
    /// - Parameter components: The set of component identifiers to check.
    /// - Returns: `true` if the components match the requirements, `false` otherwise.
    /// - Complexity: O(T) where T is the total number of required and excluded components.
    @inlinable
    public func isMatch(components: Set<ComponentIdentifier>) -> Bool {
        hasAll(components) && hasNone(components)
    }

    /// Checks if the provided components satisfy the `requiresAll` condition.
    /// - Parameter components: The set of component identifiers.
    /// - Returns: `true` if all required components are present.
    /// - Complexity: O(R) where R is the number of required components.
    @inlinable
    public func hasAll(_ components: Set<ComponentIdentifier>) -> Bool {
        requiresAll.isSubset(of: components)
    }

    /// Checks if the provided components satisfy the `excludesAll` condition.
    /// - Parameter components: The set of component identifiers.
    /// - Returns: `true` if none of the excluded components are present.
    /// - Complexity: O(E) where E is the number of excluded components.
    @inlinable
    public func hasNone(_ components: Set<ComponentIdentifier>) -> Bool {
        excludesAll.isDisjoint(with: components)
    }

    /// Validates if the trait set is logically consistent.
    /// - Parameters:
    ///   - requiresAll: The required components.
    ///   - excludesAll: The excluded components.
    /// - Returns: `true` if the trait set is valid (non-empty requirements and disjoint exclusion).
    @inlinable
    public static func isValid(requiresAll: Set<ComponentIdentifier>, excludesAll: Set<ComponentIdentifier>) -> Bool {
        !requiresAll.isEmpty &&
            requiresAll.isDisjoint(with: excludesAll)
    }
}

extension FamilyTraitSet: Equatable {
    /// Returns a Boolean value indicating whether two family trait sets are equal.
    /// - Parameters:
    ///   - lhs: A family trait set to compare.
    ///   - rhs: Another family trait set to compare.
    public static func == (lhs: FamilyTraitSet, rhs: FamilyTraitSet) -> Bool {
        lhs.setHash == rhs.setHash
    }
}

extension FamilyTraitSet: Hashable {
    /// Hashes the essential components of this value by feeding them into the given hasher.
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    /// - Complexity: O(1)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(setHash)
    }
}

extension FamilyTraitSet: Sendable {}

extension FamilyTraitSet: CustomStringConvertible {
    /// A textual representation of the family trait set.
    /// - Complexity: O(R + E) where R is the number of required components and E is the number of excluded components.
    @inlinable public var description: String {
        "<FamilyTraitSet [requiresAll:\(requiresAll.description) excludesAll:\(excludesAll.description)]>"
    }
}

extension FamilyTraitSet: CustomDebugStringConvertible {
    /// A textual representation of the family trait set, suitable for debugging.
    /// - Complexity: O(R + E) where R is the number of required components and E is the number of excluded components.
    @inlinable public var debugDescription: String {
        "<FamilyTraitSet [requiresAll:\(requiresAll.debugDescription) excludesAll: \(excludesAll.debugDescription)]>"
    }
}
