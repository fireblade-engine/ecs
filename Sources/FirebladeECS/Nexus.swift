//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

/// entity id ^ component identifier hash
public typealias EntityComponentHash = Int
public typealias ComponentIndex = Int
public extension ComponentIndex {
	static let invalid: ComponentIndex = Int.min
}
public typealias ComponentIdsByEntityIndex = Int
public typealias ComponentTypeHash = Int // component object identifier hash value

public typealias UniformComponents = ContiguousArray<Component>
public typealias ComponentIdentifiers = ContiguousArray<ComponentIdentifier>
public typealias ComponentSet = Set<ComponentIdentifier>
public typealias Entities = ContiguousArray<Entity>
public typealias EntityIdSet = Set<EntityIdentifier>
public typealias FamilyTraitSetHash = Int

public class Nexus {

	/// - Index: index value matching entity identifier shifted to Int
	/// - Value: each element is a entity instance
	var entities: Entities

	/// - Key: component type identifier
	/// - Value: each element is a component instance of the same type (uniform). New component instances are appended.
	var componentsByType: [ComponentIdentifier: UniformComponents]

	/// - Key: 'entity id' - 'component type' hash that uniquely links both
	///	- Value: each element is an index pointing to the component instance index in the componentsByType map.
	var componentIndexByEntityComponentHash: [EntityComponentHash: ComponentIndex]

	/// - Key: entity id as index
	/// - Value: each element is a component identifier associated with this entity
	var componentIdsByEntity: [EntityIndex: ComponentIdentifiers]

	/// - Key 'entity id' - 'component type' hash that uniquely links both
	/// - Value: each element is an index pointing to the component identifier per entity in the componentIdsByEntity map
	var componentIdsByEntityLookup: [EntityComponentHash: ComponentIdsByEntityIndex]

	/// - Values: entity ids that are currently not used
	var freeEntities: ContiguousArray<EntityIdentifier>

	var familiyByTraitHash: [FamilyTraitSetHash: Family]
	var familyMembersByTraitHash: [FamilyTraitSetHash: EntityIdSet]
	var componentIdsSetByEntity: [EntityIndex: ComponentSet]

	public init() {
		entities = Entities()
		componentsByType = [:]
		componentIndexByEntityComponentHash = [:]
		componentIdsByEntity = [:]
		componentIdsSetByEntity = [:]
		componentIdsByEntityLookup = [:]
		freeEntities = ContiguousArray<EntityIdentifier>()
		familiyByTraitHash = [:]
		familyMembersByTraitHash = [:]
	}

}

extension Nexus {

	func notify(_ event: Event) {
		//Log.debug(event)
		// TODO: implement
	}

	func report(_ message: String) {
		Log.warn(message)
		// TODO: implement
	}
}

/*
// MARK: - event handler
extension Nexus {
	func handleEntityCreated(_ e: EntityCreated) { print(e) }
	func handleEntityDestroyed(_ e: EntityDestroyed) { print(e) }

	func handleComponentAdded(_ e: ComponentAdded) { print(e) }
	func handleComponentUpdated(_ e: ComponentUpdated) { print(e) }
	func handleComponentRemoved(_ e: ComponentRemoved) { print(e) }

	func handleFamilyCreated(_ e: FamilyCreated) {
		print(e)
		let newFamily: Family = e.family
		onFamilyCreated(newFamily)

	}
	func handleFamilyMemberAdded(_ e: FamilyMemberAdded) { print(e) }
	func handleFamilyMemberRemoved(_ e: FamilyMemberRemoved) { print(e) }
	func handleFamilyDestroyed(_ e: FamilyDestroyed) { print(e) }
}
*/
