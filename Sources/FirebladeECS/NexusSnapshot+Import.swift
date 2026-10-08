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
    struct Import: Decodable {
        /// Decodes the snapshot into the resolver's nexus.
        /// - Parameter decoder: The decoder to read data from.
        /// - Throws: ``ComponentSerializationError`` for a missing resolver or an unsupported format version,
        ///   ``ComponentRegistryError`` or decoding errors.
        init(from decoder: Decoder) throws {
            guard let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver else {
                throw ComponentSerializationError.missingImportContext
            }
            let nexus = resolver.nexus
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let formatVersion = try container.decode(UInt.self, forKey: .formatVersion)
            guard formatVersion <= NexusSnapshot.formatVersion else {
                throw ComponentSerializationError.unsupportedFormatVersion(formatVersion)
            }

            var identifiers = try container.nestedUnkeyedContainer(forKey: .entities)
            while !identifiers.isAtEnd {
                let member = try identifiers.nestedContainer(keyedBy: MemberCodingKeys.self)
                let sourceId = try member.decode(EntityIdentifier.self, forKey: .id)
                resolver.map(sourceId, to: nexus.createEntity().identifier)
            }

            var entities = try container.nestedUnkeyedContainer(forKey: .entities)
            while !entities.isAtEnd {
                let member = try entities.nestedContainer(keyedBy: MemberCodingKeys.self)
                let entity = try resolver.resolve(member.decode(EntityIdentifier.self, forKey: .id))
                let components = try member.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .components)
                var decoded: [Component] = []
                for key in components.allKeys {
                    guard let record = nexus.componentType(named: key.stringValue) else {
                        throw ComponentRegistryError.unknownTypeName(key.stringValue)
                    }
                    guard let serializableType = record.type as? any SerializableComponent.Type else {
                        throw ComponentSerializationError.notSerializable(typeName: record.typeName)
                    }
                    try decoded.append(Self.decode(serializableType, from: components, forKey: key))
                }
                nexus.assign(components: decoded, to: entity.identifier)
            }
        }

        /// Decodes a component of a concrete serializable type.
        private static func decode<C: SerializableComponent>(
            _ type: C.Type,
            from container: KeyedDecodingContainer<DynamicCodingKey>,
            forKey key: DynamicCodingKey
        ) throws -> C {
            try container.decode(type, forKey: key)
        }
    }
}
