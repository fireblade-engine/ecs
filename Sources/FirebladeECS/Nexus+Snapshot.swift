//
//  Nexus+Snapshot.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Nexus {
    /// Creates a snapshot of all entities and their serializable components.
    /// - Parameter handling: Defines how components that are not serializable are treated.
    /// - Returns: A snapshot referencing the live component instances.
    /// - Throws: ``ComponentSerializationError/notSerializable(typeName:)`` if `handling` is ``NonSerializableComponentHandling/throwError``
    ///   and a component is not serializable.
    /// - Complexity: O(E * C log C) where E is the number of entities and C the number of components per entity.
    public final func makeSnapshot(handling: NonSerializableComponentHandling) throws -> NexusSnapshot {
        let entityIds = componentIdsByEntity.keys.sorted { $0.id < $1.id }
        var members: [NexusSnapshot.Member] = []
        members.reserveCapacity(entityIds.count)
        for entityId in entityIds {
            var components: [any SerializableComponent] = []
            for componentId in componentIdsByEntity[entityId, default: []] {
                let component = get(unsafe: componentId, for: entityId)
                guard let serializable = component as? any SerializableComponent else {
                    switch handling {
                    case .throwError:
                        throw ComponentSerializationError.notSerializable(typeName: String(reflecting: type(of: component)))

                    case .skip:
                        continue
                    }
                }
                components.append(serializable)
            }
            components.sort { type(of: $0).componentTypeName < type(of: $1).componentTypeName }
            members.append(NexusSnapshot.Member(identifier: entityId, components: components))
        }
        return NexusSnapshot(members: members)
    }
}

#if canImport(Foundation)
    extension Nexus {
        /// Encodes all entities and their serializable components.
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
            guard let resolverValue = resolver as? SnapshotDecoder.UserInfoValue else {
                throw ComponentSerializationError.missingImportContext
            }
            let previousResolver = decoder.userInfo[.nexusEntityResolver]
            decoder.userInfo[.nexusEntityResolver] = resolverValue
            defer { decoder.userInfo[.nexusEntityResolver] = previousResolver }
            do {
                _ = try decoder.decode(NexusSnapshot.Import.self, from: data)
            } catch {
                for createdId in resolver.mapping.values {
                    destroy(entityId: createdId)
                }
                throw error
            }
            return resolver.mapping.mapValues { Entity(nexus: self, id: $0) }
        }
    }
#endif
