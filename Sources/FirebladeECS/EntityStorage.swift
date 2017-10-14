//
//  EntityStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 10.10.17.
//

public protocol EntityStorage {

	func create(in nexus: Nexus) -> Entity

	@discardableResult func add(_ entity: Entity) -> Bool

	var iterator: AnyIterator<Entity> { get }

	func has(_ entity: Entity) -> Bool
	func has(_ id: EntityIdentifier) -> Bool
	func has(_ named: String) -> Bool

	func get(_ id: EntityIdentifier) -> Entity?
	subscript(_ id: EntityIdentifier) -> Entity? { get }

	func get(_ named: String) -> Entity?
	subscript(_ named: String) -> Entity? { get }

	@discardableResult func remove(_ id: EntityIdentifier) -> Bool

	func clear()
}

class GeneralEntityStorage: EntityStorage {

	fileprivate typealias Index = ContiguousArray<Entity>.Index
	fileprivate var entities: ContiguousArray<Entity> = ContiguousArray<Entity>()

	var iterator: AnyIterator<Entity> {
		return AnyIterator(entities.makeIterator())
	}

	func create(in nexus: Nexus) -> Entity {
		let nextIndex = EntityIdentifier(entities.count) // TODO: should be next free index -> reuse
		return Entity(nexus: nexus, id: nextIndex)
	}

	@discardableResult
	func add(_ entity: Entity) -> Bool {
		assert(!entities.contains(entity), "entity already present")
		entities.append(entity)
		return true
	}

	func has(_ entity: Entity) -> Bool {
		return entities.contains(entity)
	}

	func has(_ id: EntityIdentifier) -> Bool {
		return entities.contains { $0.identifier == id }
	}

	func has(_ named: String) -> Bool {
		return entities.contains { $0.name == named }
	}

	func get(_ id: EntityIdentifier) -> Entity? {
		guard let index = index(id) else { return nil }
		return entities[index]
	}

	subscript(id: EntityIdentifier) -> Entity? { return get(id) }

	func get(_ named: String) -> Entity? {
		guard let index: Index = index(named) else { return nil }
		return entities[index]
	}

	subscript(named: String) -> Entity? { return get(named)	}

	@discardableResult
	func remove(_ id: EntityIdentifier) -> Bool {
		guard let index: Index = index(id) else { return false }
		entities.remove(at: index)
		return true
	}

	func clear() {
		entities.removeAll()
	}

	// MARK: - internal

	fileprivate func index(_ id: EntityIdentifier) -> Index? {
		return Index(id)
		//return entities.index { $0.uei == id }
	}

	fileprivate func index(_ named: String) -> Index? {
		return entities.index { $0.name == named }
	}

}
