//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

/// entity id ^ component identifier hash
public typealias EntityComponentHash = Int
public typealias ComponentIdsByEntityIndex = Int
public typealias ComponentTypeHash = Int // component object identifier hash value

public typealias UniformComponents = ContiguousComponentArray
public typealias ComponentIdentifiers = ContiguousArray<ComponentIdentifier>
public typealias ComponentSet = Set<ComponentIdentifier>
public typealias Entities = ContiguousArray<Entity>
public typealias EntityIdSet = Set<EntityIdentifier>
public typealias FamilyTraitSetHash = Int
public typealias TraitEntityIdHash = Int
public typealias EntityIdInFamilyIndex = Int
public typealias TraitEntityIdHashSet = [TraitEntityIdHash: EntityIdInFamilyIndex]

public class Nexus {

	/// - Index: index value matching entity identifier shifted to Int
	/// - Value: each element is a entity instance
	var entityStorage: Entities

	/// - Key: component type identifier
	/// - Value: each element is a component instance of the same type (uniform). New component instances are appended.
	var componentsByType: [ComponentIdentifier: SparseComponentSet]

	/// - Key: entity id as index
	/// - Value: each element is a component identifier associated with this entity
	var componentIdsByEntity: [EntityIndex: ComponentIdentifiers]

	/// - Key 'entity id' - 'component type' hash that uniquely links both
	/// - Value: each element is an index pointing to the component identifier per entity in the componentIdsByEntity map
	var componentIdsByEntityLookup: [EntityComponentHash: ComponentIdsByEntityIndex]

	/// - Values: entity ids that are currently not used
	var freeEntities: ContiguousArray<EntityIdentifier>

	var familiyByTraitHash: [FamilyTraitSetHash: Family]
	var familyMembersByTraitHash: [FamilyTraitSetHash: [EntityIdentifier]] // SparseSet for EntityIdentifier
	var familyContainsEntityId: [TraitEntityIdHash: Bool]

	public init() {
		entityStorage = Entities()
		componentsByType = [:]
		componentIdsByEntity = [:]
		componentIdsByEntityLookup = [:]
		freeEntities = ContiguousArray<EntityIdentifier>()
		familiyByTraitHash = [:]
		familyMembersByTraitHash = [:]
		familyContainsEntityId = [:]
	}

}

extension Nexus {

	func notify(_ event: Event) {
		//Log.debug(event)
		// TODO: implement

	}

	func report(_ message: String) {
		// TODO: implement
	}
}
