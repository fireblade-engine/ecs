//
//  Nexus+Family.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {

	/*@discardableResult
	public func family(with traits: FamilyTraits) -> (new: Bool, family: Family) {

		if let existingFamily: Family = families.get(traits) {
			return (new: false, family: existingFamily)
		}

		let newFamily = Family(self, traits: traits)
		// ^ dispatches family creation event here ^
		let success = families.add(newFamily)
		assert(success, "Family with the exact traits already exists")

		refreshFamilyCache()

		return (new: true, family: newFamily)
	}

	func onFamilyCreated(_ newFamily: Family) {
		newFamily.update(membership: entities.iterator)
	}

	func refreshFamilyCache() {
		// TODO:
	}
	*/

}
