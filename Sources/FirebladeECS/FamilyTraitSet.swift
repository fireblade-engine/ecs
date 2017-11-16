//
//  FamilyTraitSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public struct FamilyTraitSet {

	fileprivate let requiresAll: ComponentSet
	fileprivate let excludesAll: ComponentSet
	fileprivate let needsAtLeastOne: ComponentSet
	fileprivate let _hash: Int
	fileprivate let isEmptyAny: Bool

	public init(requiresAll: [Component.Type], excludesAll: [Component.Type], needsAtLeastOne: [Component.Type] = []) {

		let all = ComponentSet(requiresAll.map { $0.identifier })
		let none = ComponentSet(excludesAll.map { $0.identifier })
		let one = ComponentSet(needsAtLeastOne.map { $0.identifier })

		let valid: Bool = FamilyTraitSet.isValid(requiresAll: all, excludesAll: none, atLeastOne: one)
		assert(valid, "invalid family trait created - requiresAll: \(all), excludesAll: \(none), atLeastOne: \(one)")

		isEmptyAny = one.isEmpty

		_hash = hash(combine: [all, one, none])

		self.requiresAll = all
		self.needsAtLeastOne = one
		self.excludesAll = none
	}
}

// MARK: - match
extension FamilyTraitSet {
	public func isMatch(components: ComponentSet) -> Bool {
		return hasAll(components) && hasNone(components) && hasOne(components)
	}

	fileprivate func hasAll(_ components: ComponentSet) -> Bool {
		return requiresAll.isSubset(of: components)
	}

	fileprivate func hasNone(_ components: ComponentSet) -> Bool {
		return excludesAll.isDisjoint(with: components)
	}

	fileprivate func hasOne(_ components: ComponentSet) -> Bool {
		if needsAtLeastOne.isEmpty { return true }
		return !needsAtLeastOne.intersection(components).isEmpty
	}
}

// MARK: - valid
extension FamilyTraitSet {
	fileprivate static func isValid(requiresAll: ComponentSet,
									excludesAll: ComponentSet,
									atLeastOne: ComponentSet) -> Bool {
		return validAtLeastOneNonEmpty(requiresAll, atLeastOne) &&
			requiresAll.isDisjoint(with: atLeastOne) &&
			requiresAll.isDisjoint(with: excludesAll) &&
			atLeastOne.isDisjoint(with: excludesAll)
	}

	fileprivate static func validAtLeastOneNonEmpty(_ requiresAll: ComponentSet, _ atLeastOne: ComponentSet) -> Bool {
		return !requiresAll.isEmpty || !atLeastOne.isEmpty
	}

}

// MARK: - Equatable
extension FamilyTraitSet: Equatable {
	public static func ==(lhs: FamilyTraitSet, rhs: FamilyTraitSet) -> Bool {
		return lhs._hash == rhs._hash
	}
}

// MARK: - Hashable
extension FamilyTraitSet: Hashable {
	public var hashValue: Int {
		return _hash
	}
}

