//
//  FamilyTraitSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public struct FamilyTraitSet {
    public let requiresAll: ComponentSet
    public let excludesAll: ComponentSet

    public let setHash: Int

    public init(requiresAll: [Component.Type], excludesAll: [Component.Type]) {
        let requiresAll = ComponentSet(requiresAll.map { $0.identifier })
        let excludesAll = ComponentSet(excludesAll.map { $0.identifier })

        let valid: Bool = FamilyTraitSet.isValid(requiresAll: requiresAll, excludesAll: excludesAll)
        precondition(valid, "invalid family trait created - requiresAll: \(requiresAll), excludesAll: \(excludesAll)")

        self.requiresAll = requiresAll
        self.excludesAll = excludesAll
        self.setHash = FirebladeECS.hash(combine: [requiresAll, excludesAll])
    }

    // MARK: - match
    @inlinable
    public func isMatch(components: ComponentSet) -> Bool {
        return hasAll(components) && hasNone(components)
    }

    @inlinable
    public func hasAll(_ components: ComponentSet) -> Bool {
        return requiresAll.isSubset(of: components)
    }

    @inlinable
    public func hasNone(_ components: ComponentSet) -> Bool {
        return excludesAll.isDisjoint(with: components)
    }

    // MARK: - valid
    @inlinable
    public static func isValid(requiresAll: ComponentSet, excludesAll: ComponentSet) -> Bool {
        return !requiresAll.isEmpty &&
            requiresAll.isDisjoint(with: excludesAll)
    }
}

// MARK: - Equatable
extension FamilyTraitSet: Equatable {
    public static func == (lhs: FamilyTraitSet, rhs: FamilyTraitSet) -> Bool {
        return lhs.setHash == rhs.setHash
    }
}

// MARK: - Hashable
extension FamilyTraitSet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(setHash)
    }
}

extension FamilyTraitSet: CustomStringConvertible, CustomDebugStringConvertible {
    @inlinable public var description: String {
        return "<FamilyTraitSet [requiresAll:\(requiresAll.description) excludesAll:\(excludesAll.description)]>"
    }

    @inlinable public var debugDescription: String {
        return "<FamilyTraitSet [requiresAll:\(requiresAll.debugDescription) excludesAll: \(excludesAll.debugDescription)]>"
    }
}
