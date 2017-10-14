//
//  EntityHub2.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 11.10.17.
//

class EntityHub2 {
/*
	fileprivate typealias CompType = ComponentIdentifier
	fileprivate typealias CompIdxInCompArrayForType = Int
	fileprivate typealias ComponentArray = ContiguousArray<Component>
	fileprivate typealias EntityID = Int // aka EntityIdentifier

	fileprivate var componentsByType: [CompType: ComponentArray] = [:]
	fileprivate var entitiesById: [EntityID: Entity] = [:]
	fileprivate var componentLookupByEntityId: [EntityID: [CompType:CompIdxInCompArrayForType]] = [:]
	fileprivate var entityIdLookupByCompType: [CompType: [CompIdxInCompArrayForType:EntityID]] = [:]


	fileprivate func query(_ compTypes: Component.Type...) -> [Entity] {
		let types = compTypes.map{ $0.identifier }
		fatalError()
	}

	fileprivate func queryTypes(_ types: [CompType]) -> [Entity] {
		var types = types

		var minSize: Int = Int.max
		var minIndex: Int = 0
		var index: Int = 0

		for t in types {
			guard let compArray = componentsByType[t] else {
				fatalError("querying for non existing type \(t.type)")
			}

			let size: Int = compArray.count
			if size < minSize {
				minSize = size
				minIndex = index
			}
			index += 1
		}

		let minType: CompType = types[minIndex]

		if types.count >= 2 && minIndex != (types.count - 1) {
			types.swapAt(minIndex, (types.count-1))
		}
		types.removeLast()

		return iterate(minType, types)
	}

	fileprivate func iterate(_ minType: CompType, _ types: [CompType]) -> [Entity] {
		var entitiesWithTypes: [Entity] = []

		guard let compArray = componentsByType[minType] else {
			fatalError("iterating non existing type \(minType.type)")
		}

		for i: CompIdxInCompArrayForType in 0..<compArray.count {

			let component = compArray[i]
			let compType = component.identifier

			guard let ownerId: EntityID = entityIdLookupByCompType[compType]?[i]else {
				fatalError("could not find owner id")
			}

			if has(allTypes: ownerId, types) {
				guard let entity = entitiesById[ownerId] else {
					fatalError("could not find entity")
				}
				entitiesWithTypes.append(entity)
			}
		}

		return entitiesWithTypes

	}

	fileprivate func has(allTypes entityId: EntityID, _ types: [CompType]) -> Bool {
		guard let entityTypes = componentLookupByEntityId[entityId]?.keys else { return false }

		for requiredType: CompType in types {
			if !entityTypes.contains(requiredType) { return false }
		}
		return true



	}
*/
}
