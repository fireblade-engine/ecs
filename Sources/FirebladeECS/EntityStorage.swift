//
//  EntityStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 10.10.17.
//

public protocol EntityStorage {
	@discardableResult func add(_ entity: Entity) -> Bool

	var iterator: AnyIterator<Entity> { get }

	func has(_ entity: Entity) -> Bool
	func has(_ id: UEI) -> Bool
	func has(_ named: String) -> Bool

	func get(_ id: UEI) -> Entity?
	subscript(_ id: UEI) -> Entity? { get }

	func get(_ named: String) -> Entity?
	subscript(_ named: String) -> Entity? { get }

	@discardableResult func remove(_ id: UEI) -> Bool

	func clear()

}

class DefaultEntityStorage: EntityStorage {

	fileprivate typealias Index = Set<Entity>.Index
	fileprivate var entities: Set<Entity> = Set<Entity>()

	var iterator: AnyIterator<Entity> {
		return AnyIterator(entities.makeIterator())
	}

	@discardableResult
	func add(_ entity: Entity) -> Bool {
		let (success, _) = entities.insert(entity)
		return success
	}

	func has(_ entity: Entity) -> Bool {
		return entities.contains(entity)
	}

	func has(_ id: UEI) -> Bool {
		return entities.contains { $0.uei == id }
	}

	func has(_ named: String) -> Bool {
		return entities.contains { $0.name == named }
	}

	func get(_ id: UEI) -> Entity? {
		guard let index = index(id) else { return nil }
		return entities[index]
	}

	subscript(id: UEI) -> Entity? { return get(id) }

	func get(_ named: String) -> Entity? {
		guard let index: Index = index(named) else { return nil }
		return entities[index]
	}

	subscript(named: String) -> Entity? { return get(named)	}

	@discardableResult
	func remove(_ id: UEI) -> Bool {
		guard let index: Index = index(id) else { return false }
		entities.remove(at: index)
		return true
	}

	func clear() {
		entities.removeAll()
	}

	// MARK: - internal

	fileprivate func index(_ id: UEI) -> Index? {
		return entities.index { $0.uei == id }
	}

	fileprivate func index(_ named: String) -> Index? {
		return entities.index { $0.name == named }
	}

}
