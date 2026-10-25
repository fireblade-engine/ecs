//
//  Nexus+Clone.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Nexus {
    /// Clones an entity and all of its components within this nexus.
    ///
    /// References of the entity's components to the entity itself are remapped to the clone.
    /// - Parameter entity: The entity to clone.
    /// - Returns: The cloned entity.
    /// - Throws: ``ComponentCloneError`` if the entity does not exist or a component is not cloneable.
    ///   Nothing is created in that case.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public final func clone(entity: Entity) throws -> Entity {
        let mapping = try clone(entityIds: [entity.identifier], into: self)
        return Entity(nexus: self, id: mapping[entity.identifier].unsafelyUnwrapped)
    }

    /// Clones a group of entities and all of their components within this nexus.
    ///
    /// References between entities of the group are remapped to the clones.
    /// References to entities outside of the group are kept unchanged.
    /// - Parameter entities: The entities to clone.
    /// - Returns: The cloned entities in the order of `entities`.
    /// - Throws: ``ComponentCloneError`` if an entity does not exist or a component is not cloneable.
    ///   Nothing is created in that case.
    /// - Complexity: O(E * (C + M)) where E is the number of entities, C the number of components per entity and M the number of families.
    @discardableResult
    public final func clone(entities: some Sequence<Entity>) throws -> [Entity] {
        let sourceIds = entities.map(\.identifier)
        let mapping = try clone(entityIds: sourceIds, into: self)
        return sourceIds.map { Entity(nexus: self, id: mapping[$0].unsafelyUnwrapped) }
    }

    /// Clones all entities and their components of this nexus into a target nexus.
    ///
    /// All references between entities are remapped to the clones in the target nexus.
    /// Entities are cloned in ascending order of their identifiers.
    /// - Parameter target: The nexus to create the clones in.
    /// - Returns: The mapping from source entity identifiers to the cloned entities.
    /// - Throws: ``ComponentCloneError/notCloneable(typeName:)`` if a component is not cloneable.
    ///   Nothing is created in that case.
    /// - Complexity: O(E * (C + M)) where E is the number of entities, C the number of components per entity and M the number of families.
    @discardableResult
    public final func clone(into target: Nexus) throws -> [EntityIdentifier: Entity] {
        let sourceIds = componentIdsByEntity.keys.sorted { $0.id < $1.id }
        let mapping = try clone(entityIds: sourceIds, into: target)
        return mapping.mapValues { Entity(nexus: target, id: $0) }
    }

    /// Clones entities into a target nexus.
    ///
    /// Validates all components before creating any entity, then creates all clones
    /// before cloning components so that references between them can be remapped.
    /// - Parameters:
    ///   - sourceIds: The identifiers of the entities to clone. Duplicates are cloned once.
    ///   - target: The nexus to create the clones in.
    /// - Returns: The mapping from source entity identifiers to the identifiers of their clones.
    /// - Throws: ``ComponentCloneError`` if an entity does not exist or a component is not cloneable.
    func clone(entityIds sourceIds: [EntityIdentifier], into target: Nexus) throws -> [EntityIdentifier: EntityIdentifier] {
        var componentsBySource: [(EntityIdentifier, [any CloneableComponent])] = []
        var visited: Set<EntityIdentifier> = []
        for sourceId in sourceIds where visited.insert(sourceId).inserted {
            guard let componentIds = componentIdsByEntity[sourceId] else {
                throw ComponentCloneError.unknownEntity(sourceId)
            }
            var components: [any CloneableComponent] = []
            for componentId in componentIds {
                let component = unsafeComponent(componentId, for: sourceId)
                guard let cloneable = component as? any CloneableComponent else {
                    throw ComponentCloneError.notCloneable(typeName: String(reflecting: type(of: component)))
                }
                components.append(cloneable)
            }
            componentsBySource.append((sourceId, components))
        }

        var mapping: [EntityIdentifier: EntityIdentifier] = [:]
        for (sourceId, _) in componentsBySource {
            mapping[sourceId] = target.createEntity().identifier
        }

        let context = ComponentCloneContext(nexus: target, mapping: mapping)
        for (sourceId, components) in componentsBySource {
            let clones: [Component] = components.map { $0.clone(context: context) }
            target.assign(components: clones, to: mapping[sourceId].unsafelyUnwrapped)
        }
        return mapping
    }
}
