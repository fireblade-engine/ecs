//
//  FamilyStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 10.10.17.
//

public protocol FamilyStorage {
	@discardableResult func add(_ family: Family) -> Bool

	var iterator: AnyIterator<(FamilyTraits, Family)> { get }

	func has(_ family: Family) -> Bool
	func has(_ traits: FamilyTraits) -> Bool

	func get(_ traits: FamilyTraits) -> Family?
	subscript(_ traits: FamilyTraits) -> Family? { get }

	@discardableResult func remove(_ family: Family) -> Bool
	@discardableResult func remove(_ traits: FamilyTraits) -> Bool

	func clear()
}

class GeneralFamilyStorage: FamilyStorage {

	fileprivate typealias Index = Dictionary<FamilyTraits, Family>.Index
	fileprivate var families: [FamilyTraits: Family] = [:]

	var iterator: AnyIterator<(FamilyTraits, Family)> {
		// see: https://www.raywenderlich.com/139591/building-custom-collection-swift
		var iter = families.makeIterator()
		return AnyIterator<(FamilyTraits, Family)> {
			return iter.next()
		}
	}

	func add(_ family: Family) -> Bool {
		let replaced: Family? = families.updateValue(family, forKey: family.traits)
		let success: Bool = replaced == nil
		assert(success)
		return success
	}

	func has(_ family: Family) -> Bool {
		return index(family) != nil
	}

	func has(_ traits: FamilyTraits) -> Bool {
		return index(traits) != nil
	}

	func get(_ traits: FamilyTraits) -> Family? {
		return families[traits]
	}

	subscript(_ traits: FamilyTraits) -> Family? {
		return get(traits)
	}

	func remove(_ family: Family) -> Bool {
		guard let index = index(family) else { return false }
		families.remove(at: index)
		return true
	}

	func remove(_ traits: FamilyTraits) -> Bool {
		guard let index = index(traits) else { return false }
		families.remove(at: index)
		return true
	}

	func clear() {
		families.removeAll()
	}

	// MARK: - private
	private func index(_ traits: FamilyTraits) -> Index? {
		return families.index(forKey: traits)
	}

	private func index(_ family: Family) -> Index? {
		return index(family.traits)
	}

}
