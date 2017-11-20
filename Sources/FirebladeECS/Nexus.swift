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
public typealias UniformEntityIdentifiers = SparseEntityIdentifierSet
public typealias ComponentIdentifiers = ContiguousArray<ComponentIdentifier>
public typealias ComponentSet = Set<ComponentIdentifier>
public typealias Entities = SparseEntitySet
public typealias EntityIdSet = Set<EntityIdentifier>
public typealias FamilyTraitSetHash = Int
public typealias TraitEntityIdHash = Int
public typealias EntityIdInFamilyIndex = Int
public typealias TraitEntityIdHashSet = [TraitEntityIdHash: EntityIdInFamilyIndex]

public protocol NexusDelegate: class {
	func nexusEventOccurred(_ event: ECSEvent)
	func nexusRecoverableErrorOccurred(_ message: String)
}

public class Nexus {

	weak var delegate: NexusDelegate?

	/// - Index: index value matching entity identifier shifted to Int
	/// - Value: each element is a entity instance
	var entityStorage: Entities

	/// - Key: component type identifier
	/// - Value: each element is a component instance of the same type (uniform). New component instances are appended.
	var componentsByType: [ComponentIdentifier: UniformComponents]

	/// - Key: entity id as index
	/// - Value: each element is a component identifier associated with this entity
	var componentIdsByEntity: [EntityIndex: SparseComponentIdentifierSet]

	/// - Values: entity ids that are currently not used
	var freeEntities: ContiguousArray<EntityIdentifier>

	var familiesByTraitHash: [FamilyTraitSetHash: Family]
	var familyMembersByTraitHash: [FamilyTraitSetHash: UniformEntityIdentifiers]

	public init() {
		entityStorage = Entities()
		componentsByType = [:]
		componentIdsByEntity = [:]
		//componentIdsByEntityLookup = [:]
		freeEntities = ContiguousArray<EntityIdentifier>()
		familiesByTraitHash = [:]
		familyMembersByTraitHash = [:]

	}

	deinit {

		for e: Entity in entityStorage {
			destroy(entity: e)
		}

		entityStorage.clear()
		freeEntities.removeAll()

		assert(entityStorage.isEmpty)
		assert(componentsByType.values.reduce(0) { $0 + $1.count } == 0)
		assert(componentIdsByEntity.values.reduce(0) { $0 + $1.count } == 0)
		assert(freeEntities.isEmpty)
		assert(familiesByTraitHash.values.reduce(0) { $0 + $1.count } == 0)
		assert(familyMembersByTraitHash.values.reduce(0) { $0 + $1.count } == 0)

		componentsByType.removeAll()
		componentIdsByEntity.removeAll()
		familiesByTraitHash.removeAll()
		familyMembersByTraitHash.removeAll()
	}

}

// MARK: - nexus delegate
extension Nexus {

	func notify(_ event: ECSEvent) {
		delegate?.nexusEventOccurred(event)
	}

	func report(_ message: String) {
		delegate?.nexusRecoverableErrorOccurred(message)
	}
}
