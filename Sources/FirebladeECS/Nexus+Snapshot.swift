//
//  Nexus+Snapshot.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Nexus {
    /// Creates a snapshot of all entities, their serializable components and the entity identifier generator state.
    ///
    /// Component instances shared by several entities are listed once and referenced by the other entities.
    /// - Parameter handling: Defines how components that are not serializable are treated.
    /// - Returns: A snapshot referencing the live component instances and entity identifier generator.
    /// - Throws: ``ComponentSerializationError/notSerializable(typeName:)`` if `handling` is ``NonSerializableComponentHandling/throwError``
    ///   and a component is not serializable.
    /// - Complexity: O(E * C log C) where E is the number of entities and C the number of components per entity.
    public final func makeSnapshot(handling: NonSerializableComponentHandling) throws -> NexusSnapshot {
        let entityIds = componentIdsByEntity.keys.sorted { $0.id < $1.id }
        var owners: [ObjectIdentifier: EntityIdentifier] = [:]
        var members: [NexusSnapshot.Member] = []
        members.reserveCapacity(entityIds.count)
        for entityId in entityIds {
            var components: [any SerializableComponent] = []
            var sharedComponents: [String: EntityIdentifier] = [:]
            for componentId in componentIdsByEntity[entityId, default: []] {
                let component = unsafeComponent(componentId, for: entityId)
                guard let serializable = component as? any SerializableComponent else {
                    switch handling {
                    case .throwError:
                        throw ComponentSerializationError.notSerializable(typeName: String(reflecting: type(of: component)))

                    case .skip:
                        continue
                    }
                }
                if let owner = owners[ObjectIdentifier(component)] {
                    sharedComponents[type(of: serializable).componentTypeName] = owner
                } else {
                    owners[ObjectIdentifier(component)] = entityId
                    components.append(serializable)
                }
            }
            components.sort { type(of: $0).componentTypeName < type(of: $1).componentTypeName }
            members.append(NexusSnapshot.Member(identifier: entityId, components: components, sharedComponents: sharedComponents))
        }
        return NexusSnapshot(members: members, entityIdGenerator: entityIdGenerator as? any PersistableEntityIdentifierGenerator)
    }

    /// Recreates entities with the given identifiers in this nexus.
    ///
    /// Replaces the entity identifier generator by a new generator of the same type providing the given identifiers.
    /// - Parameter identifiers: The identifiers of the entities to create, in creation order.
    /// - Throws: ``ComponentSerializationError/entityIdentifierMismatch(expected:actual:)`` if the generator provides another identifier.
    /// - Complexity: O(N) where N is the number of identifiers.
    func recreateEntities(withIdentifiers identifiers: [EntityIdentifier]) throws {
        let generatorType = type(of: entityIdGenerator)
        entityIdGenerator = generatorType.init(startProviding: identifiers.reversed())
        for expected in identifiers {
            let actual = createEntity().identifier
            guard actual == expected else {
                throw ComponentSerializationError.entityIdentifierMismatch(expected: expected, actual: actual)
            }
        }
    }
}

#if canImport(Foundation)
    extension Nexus {
        /// Encodes all entities, their serializable components and the entity identifier generator state.
        /// - Parameters:
        ///   - encoder: The encoder to use.
        ///   - handling: Defines how components that are not serializable are treated.
        /// - Returns: The encoded snapshot.
        /// - Throws: ``ComponentSerializationError`` or encoding errors.
        /// - Complexity: O(E * C log C) where E is the number of entities and C the number of components per entity.
        public final func encodeSnapshot<SnapshotEncoder: TopLevelEncoder>(
            using encoder: inout SnapshotEncoder,
            handling: NonSerializableComponentHandling
        ) throws -> SnapshotEncoder.Output {
            try encoder.encode(makeSnapshot(handling: handling))
        }

        /// Decodes a snapshot into new entities of this nexus.
        ///
        /// Use this to add the content of a snapshot to a populated nexus, e.g. for prefabs.
        /// To load a snapshot with its original entity identifiers, use ``restoreSnapshot(from:using:)``.
        ///
        /// All component types of the snapshot must be registered in this nexus beforehand.
        /// Entity references inside components are remapped to the newly created entities.
        /// If decoding fails, all entities created by this call are destroyed.
        /// - Parameters:
        ///   - data: The encoded snapshot.
        ///   - decoder: The decoder to use.
        /// - Returns: The mapping from encoded entity identifiers to the created entities.
        /// - Throws: ``ComponentRegistryError/unknownTypeName(_:)`` for unregistered types,
        ///   ``ComponentSerializationError`` or decoding errors.
        /// - Complexity: O(E * (C + M)) where E is the number of entities, C the number of components per entity and M the number of families.
        @discardableResult
        public final func decodeSnapshot<SnapshotDecoder: TopLevelDecoder>(
            from data: SnapshotDecoder.Input,
            using decoder: inout SnapshotDecoder
        ) throws -> [EntityIdentifier: Entity] {
            let resolver = EntityReferenceResolver(nexus: self, mapping: [:])
            do {
                try importSnapshot(from: data, using: &decoder, resolver: resolver)
            } catch {
                for createdId in resolver.mapping.values {
                    destroy(entityId: createdId)
                }
                throw error
            }
            return resolver.mapping.mapValues { Entity(nexus: self, id: $0) }
        }

        /// Restores a snapshot into this nexus, keeping the encoded entity identifiers.
        ///
        /// The nexus must not contain entities. Families and registered component types are kept.
        /// If the snapshot contains entity identifier generator state and the generator of this nexus is a
        /// ``PersistableEntityIdentifierGenerator`` of the same kind, the state is restored as well,
        /// so that new entities receive the identifiers the encoded nexus would have provided.
        ///
        /// All component types of the snapshot must be registered in this nexus beforehand.
        /// If restoring fails, all entities created by this call are destroyed and the previous generator is reinstalled.
        /// - Parameters:
        ///   - data: The encoded snapshot.
        ///   - decoder: The decoder to use.
        /// - Throws: ``ComponentSerializationError/nexusNotEmpty`` if the nexus contains entities,
        ///   ``ComponentRegistryError/unknownTypeName(_:)`` for unregistered types,
        ///   ``ComponentSerializationError`` or decoding errors.
        /// - Complexity: O(E * (C + M)) where E is the number of entities, C the number of components per entity and M the number of families.
        public final func restoreSnapshot<SnapshotDecoder: TopLevelDecoder>(
            from data: SnapshotDecoder.Input,
            using decoder: inout SnapshotDecoder
        ) throws {
            guard numEntities == 0 else {
                throw ComponentSerializationError.nexusNotEmpty
            }
            let previousGenerator = entityIdGenerator
            let resolver = EntityReferenceResolver(nexus: self, mapping: [:])
            resolver.preservesIdentity = true
            do {
                try importSnapshot(from: data, using: &decoder, resolver: resolver)
            } catch {
                for createdId in componentIdsByEntity.keys {
                    destroy(entityId: createdId)
                }
                entityIdGenerator = previousGenerator
                throw error
            }
        }

        /// Decodes a snapshot into this nexus with the given resolver installed in the decoder's `userInfo`.
        private func importSnapshot<SnapshotDecoder: TopLevelDecoder>(
            from data: SnapshotDecoder.Input,
            using decoder: inout SnapshotDecoder,
            resolver: EntityReferenceResolver
        ) throws {
            guard let resolverValue = resolver as? SnapshotDecoder.UserInfoValue else {
                throw ComponentSerializationError.missingImportContext
            }
            let previousResolver = decoder.userInfo[.nexusEntityResolver]
            decoder.userInfo[.nexusEntityResolver] = resolverValue
            defer { decoder.userInfo[.nexusEntityResolver] = previousResolver }
            _ = try decoder.decode(NexusSnapshot.Import.self, from: data)
        }
    }
#endif
