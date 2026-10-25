//
//  NexusSnapshot+Import.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension NexusSnapshot {
    /// Decodes an encoded ``NexusSnapshot`` into the nexus of the ``EntityReferenceResolver``
    /// provided via `decoder.userInfo[.nexusEntityResolver]`.
    ///
    /// Creates all entities first, so that component properties referencing entities
    /// can be resolved regardless of their order in the snapshot.
    /// If the resolver preserves identity, the entities keep their encoded identifiers.
    struct Import: Decodable {
        /// Decodes the snapshot into the nexus of the resolver provided via `decoder.userInfo[.nexusEntityResolver]`.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: ``ComponentSerializationError`` for a missing resolver or an unsupported format version,
        ///   ``ComponentRegistryError`` or decoding errors.
        init(from decoder: Decoder) throws {
            guard let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver else {
                throw ComponentSerializationError.missingImportContext
            }
            try self.init(from: decoder, resolver: resolver)
        }

        /// Decodes the snapshot into the nexus of the given resolver.
        /// - Parameters:
        ///   - decoder: The decoder to read data from.
        ///   - resolver: The resolver to record the created entities in.
        /// - Throws: ``ComponentSerializationError``, ``ComponentRegistryError`` or decoding errors.
        init(from decoder: Decoder, resolver: EntityReferenceResolver) throws {
            let nexus = try resolver.targetNexus()
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let formatVersion = try container.decode(UInt.self, forKey: .formatVersion)
            guard formatVersion <= NexusSnapshot.formatVersion else {
                throw ComponentSerializationError.unsupportedFormatVersion(formatVersion)
            }

            let sourceIds = try Self.decodeIdentifiers(from: container)
            try Self.createEntities(sourceIds, in: nexus, resolver: resolver, container: container)
            let members = try Self.decodeMembers(from: container, in: nexus)
            for sourceId in sourceIds {
                var components = members.components[sourceId, default: [:]]
                for (typeName, owner) in members.shared[sourceId, default: [:]] {
                    let serializableType = try Self.serializableType(named: typeName, in: nexus)
                    guard let component = members.components[owner]?[serializableType.identifier] else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Entity \(sourceId) shares a \(typeName) component with entity \(owner), which does not list one."
                        ))
                    }
                    components[serializableType.identifier] = component
                }
                try nexus.assign(components: Array(components.values), to: resolver.resolve(sourceId).identifier)
            }
        }

        /// Creates the entities of a snapshot and maps their encoded identifiers in the resolver.
        ///
        /// If the resolver preserves identity, the entities keep their encoded identifiers and the encoded generator state is installed
        /// if the generator of the nexus is persistable.
        private static func createEntities(
            _ sourceIds: [EntityIdentifier],
            in nexus: Nexus,
            resolver: EntityReferenceResolver,
            container: KeyedDecodingContainer<CodingKeys>
        ) throws {
            guard resolver.preservesIdentity else {
                for sourceId in sourceIds {
                    resolver.map(sourceId, to: nexus.createEntity().identifier)
                }
                return
            }
            try nexus.recreateEntities(withIdentifiers: sourceIds)
            for sourceId in sourceIds {
                resolver.map(sourceId, to: sourceId)
            }
            guard container.contains(.entityIdGenerator) else {
                return
            }
            if let generatorType = type(of: nexus.entityIdGenerator) as? any PersistableEntityIdentifierGenerator.Type {
                nexus.entityIdGenerator = try decode(generatorType, from: container, forKey: .entityIdGenerator)
            }
        }

        /// Decodes the components and shared component references of all snapshot members.
        private static func decodeMembers(from container: KeyedDecodingContainer<CodingKeys>, in nexus: Nexus) throws -> DecodedSnapshotMembers {
            var decoded = DecodedSnapshotMembers()
            var entities = try container.nestedUnkeyedContainer(forKey: .entities)
            while !entities.isAtEnd {
                let member = try entities.nestedContainer(keyedBy: MemberCodingKeys.self)
                let sourceId = try member.decode(EntityIdentifier.self, forKey: .id)
                let components = try member.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .components)
                var memberComponents: [ComponentIdentifier: Component] = [:]
                for key in components.allKeys.sorted(by: { $0.stringValue < $1.stringValue }) {
                    let serializableType = try serializableType(named: key.stringValue, in: nexus)
                    memberComponents[serializableType.identifier] = try decode(serializableType, from: components, forKey: key)
                }
                decoded.components[sourceId] = memberComponents
                guard member.contains(.sharedComponents) else {
                    continue
                }
                let shared = try member.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .sharedComponents)
                var owners: [String: EntityIdentifier] = [:]
                for key in shared.allKeys {
                    owners[key.stringValue] = try shared.decode(EntityIdentifier.self, forKey: key)
                }
                decoded.shared[sourceId] = owners
            }
            return decoded
        }

        /// Decodes the identifiers of all entities of a snapshot.
        /// - Parameter container: The snapshot container.
        /// - Returns: The entity identifiers in snapshot order.
        /// - Throws: A decoding error if an identifier is listed more than once.
        private static func decodeIdentifiers(from container: KeyedDecodingContainer<CodingKeys>) throws -> [EntityIdentifier] {
            var entities = try container.nestedUnkeyedContainer(forKey: .entities)
            var identifiers: [EntityIdentifier] = []
            var seen: Set<EntityIdentifier> = []
            while !entities.isAtEnd {
                let member = try entities.nestedContainer(keyedBy: MemberCodingKeys.self)
                let identifier = try member.decode(EntityIdentifier.self, forKey: .id)
                guard seen.insert(identifier).inserted else {
                    throw DecodingError.dataCorruptedError(forKey: .id, in: member, debugDescription: "Entity \(identifier) is listed more than once.")
                }
                identifiers.append(identifier)
            }
            return identifiers
        }

        /// Looks up the serializable component type registered under a name or alias.
        /// - Parameters:
        ///   - typeName: The component type name or alias.
        ///   - nexus: The nexus to look the type up in.
        /// - Returns: The serializable component type.
        /// - Throws: ``ComponentRegistryError/unknownTypeName(_:)`` or ``ComponentSerializationError/notSerializable(typeName:)``.
        private static func serializableType(named typeName: String, in nexus: Nexus) throws -> any SerializableComponent.Type {
            guard let record = nexus.componentType(named: typeName) else {
                throw ComponentRegistryError.unknownTypeName(typeName)
            }
            guard let serializableType = record.type as? any SerializableComponent.Type else {
                throw ComponentSerializationError.notSerializable(typeName: record.typeName)
            }
            return serializableType
        }

        /// Decodes a value of a concrete decodable type.
        private static func decode<Value: Decodable, Key: CodingKey>(
            _ type: Value.Type,
            from container: KeyedDecodingContainer<Key>,
            forKey key: Key
        ) throws -> Value {
            try container.decode(type, forKey: key)
        }
    }
}

/// The decoded components of all snapshot members, by encoded entity identifier.
private struct DecodedSnapshotMembers {
    /// The components each entity lists itself.
    var components: [EntityIdentifier: [ComponentIdentifier: Component]] = [:]
    /// The type names of the components each entity shares, with the identifier of the entity listing the instance.
    var shared: [EntityIdentifier: [String: EntityIdentifier]] = [:]
}
