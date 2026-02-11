//
//  FamilyTraitSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public struct FamilyTraitSet {
    public let requiresAll: Set<ComponentIdentifier>
    public let excludesAll: Set<ComponentIdentifier>

    public let setHash: Int

    public init(requiresAll: [Component.Type], excludesAll: [Component.Type]) {
        let requiresAll = Set<ComponentIdentifier>(requiresAll.map { $0.identifier })
        let excludesAll = Set<ComponentIdentifier>(excludesAll.map { $0.identifier })

        assert(FamilyTraitSet.isValid(requiresAll: requiresAll, excludesAll: excludesAll), "invalid family trait created - requiresAll: \(requiresAll), excludesAll: \(excludesAll)")

        self.requiresAll = requiresAll
        self.excludesAll = excludesAll
        setHash = FirebladeECS.hash(combine: [requiresAll, excludesAll])
    }

    @inlinable
    public func isMatch(components: Set<ComponentIdentifier>) -> Bool {
        hasAll(components) && hasNone(components)
    }

    @inlinable
    public func hasAll(_ components: Set<ComponentIdentifier>) -> Bool {
        requiresAll.isSubset(of: components)
    }

    @inlinable
    public func hasNone(_ components: Set<ComponentIdentifier>) -> Bool {
        excludesAll.isDisjoint(with: components)
    }

    @inlinable
    public static func isValid(requiresAll: Set<ComponentIdentifier>, excludesAll: Set<ComponentIdentifier>) -> Bool {
        !requiresAll.isEmpty &&
            requiresAll.isDisjoint(with: excludesAll)
    }
}

extension FamilyTraitSet: Equatable {
    public static func == (lhs: FamilyTraitSet, rhs: FamilyTraitSet) -> Bool {
        lhs.setHash == rhs.setHash
    }
}

extension FamilyTraitSet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(setHash)
    }
}

extension FamilyTraitSet: Sendable {}

extension FamilyTraitSet: CustomStringConvertible {
    @inlinable public var description: String {
        "<FamilyTraitSet [requiresAll:\(requiresAll.description) excludesAll:\(excludesAll.description)]>"
    }
}

extension FamilyTraitSet: CustomDebugStringConvertible {
    @inlinable public var debugDescription: String {
        "<FamilyTraitSet [requiresAll:\(requiresAll.debugDescription) excludesAll: \(excludesAll.debugDescription)]>"
    }
}
