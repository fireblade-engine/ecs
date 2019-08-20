//
//  Typealiases.swift
//  
//
//  Created by Christian Treffs on 20.08.19.
//

/// entity id ^ component identifier hash
public typealias EntityComponentHash = Int
public typealias ComponentIdsByEntityIndex = Int
public typealias ComponentTypeHash = Int // component object identifier hash value
public typealias UniformComponents = ManagedContiguousArray<Component>
public typealias UniformEntityIdentifiers = UnorderedSparseSet<EntityIdentifier>
public typealias ComponentIdentifiers = ContiguousArray<ComponentIdentifier>
public typealias ComponentSet = Set<ComponentIdentifier>
public typealias Entities = UnorderedSparseSet<Entity>
public typealias EntityIdSet = Set<EntityIdentifier>
public typealias FamilyTraitSetHash = Int
public typealias TraitEntityIdHash = Int
public typealias EntityIdInFamilyIndex = Int
public typealias TraitEntityIdHashSet = [TraitEntityIdHash: EntityIdInFamilyIndex]
