//
//  FamilyPredicate.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

// trait/predicate/characteristic
public struct FamilyTraits {
	let hasAll: Set<UCT>
	let hasAny: Set<UCT>
	let hasNone: Set<UCT>

	public init(hasAll: Set<UCT>, hasAny: Set<UCT>, hasNone: Set<UCT>) {
		self.hasAll = hasAll
		self.hasAny = hasAny
		self.hasNone = hasNone
		assert(isValid)
	}

	fileprivate var iteratorAll: SetIterator<UCT> { return hasAll.makeIterator() }
	fileprivate var iteratorAny: SetIterator<UCT> { return hasAny.makeIterator() }
	fileprivate var iteratorNone: SetIterator<UCT> { return hasNone.makeIterator() }
}
extension FamilyTraits {
	var isValid: Bool {
		return (!hasAll.isEmpty || !hasAny.isEmpty) &&
			hasAll.isDisjoint(with: hasAny) &&
			hasAll.isDisjoint(with: hasNone) &&
			hasAny.isDisjoint(with: hasNone)
	}
}

extension FamilyTraits {

	fileprivate func matches(all entity: Entity) -> Bool {
		var all = iteratorAll
		while let uct: UCT = all.next() {
			guard entity.has(uct) else { return false }
		}
		return true
	}

	fileprivate func matches(none entity: Entity) -> Bool {
		var none = iteratorNone
		while let uct: UCT = none.next() {
			guard !entity.has(uct) else { return false }
		}
		return true
	}

	fileprivate func matches(any entity: Entity) -> Bool {
		guard !hasAny.isEmpty else { return true }
		var any = iteratorAny
		while let uct: UCT = any.next() {
			if entity.has(uct) {
				return true
			}
		}
		return false
	}

	func isMatch(_ entity: Entity) -> Bool {
		guard matches(all: entity) else { return false }
		guard matches(none: entity) else { return false }
		guard matches(any: entity) else { return false }

		return true
	}
}

// MARK: - Equatable
extension FamilyTraits: Equatable {

	fileprivate var xorHash: Int {
		return hasAll.hashValue ^ hasNone.hashValue ^ hasAny.hashValue
	}

	public static func ==(lhs: FamilyTraits, rhs: FamilyTraits) -> Bool {
		return lhs.xorHash == rhs.xorHash
	}
}

// MARK: - Hashable
extension FamilyTraits: Hashable {
	public var hashValue: Int {
		return xorHash
	}
}

// MARK: - description
extension FamilyTraits: CustomStringConvertible {

	public var description: String {
		let all: String = hasAll.map { "\($0.type)" }.joined(separator: " AND ")
		let any: String = hasAny.map { "\($0.type)" }.joined(separator: " OR ")
		let none: String = hasNone.map { "!\($0.type)"}.joined(separator: " NOT ")
		let out: String = ["\(all)", "\(any)", "\(none)"].joined(separator: " AND ")
		//TODO: nicer
		return "FamilyTraits(\(out))"
	}

}
