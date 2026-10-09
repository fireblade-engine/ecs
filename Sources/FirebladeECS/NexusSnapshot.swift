//
//  NexusSnapshot.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// An encodable view of the entities of a nexus and their serializable components.
///
/// A snapshot references the live component instances and entity identifier generator of the nexus. Encode it right after creation.
///
/// The encoded form starts with the ``formatVersion`` and lists all entities in ascending identifier order,
/// each with its original identifier and its components keyed by their stable ``RegistrableComponent/componentTypeName``:
/// ```json
/// {
///   "formatVersion": 2,
///   "entityIdGenerator": { "nextFreshId": 2, "recycled": [] },
///   "entities": [
///     { "id": 0, "components": { "MyGame.Position": { "x": 1, "y": 2 } } },
///     { "id": 1, "components": {}, "sharedComponents": { "MyGame.Position": 0 } }
///   ]
/// }
/// ```
/// - `entityIdGenerator` is present if the generator of the nexus is a ``PersistableEntityIdentifierGenerator``.
/// - `sharedComponents` is present for entities that share a component instance with an entity listed before them.
///   It maps the component type name to the identifier of the entity that encodes the instance.
///
/// Version history:
/// - 1: Entities and their components.
/// - 2: Adds `entityIdGenerator` and `sharedComponents`.
public struct NexusSnapshot {
    /// The version of the encoded snapshot format written by this library.
    ///
    /// Additions to the format increase the version.
    /// Decoding accepts all versions up to this one and rejects snapshots with a newer version.
    public static let formatVersion: UInt = 2

    /// The entities of the snapshot in ascending identifier order.
    public let members: [Member]

    /// The entity identifier generator of the nexus, if it can be persisted.
    public let entityIdGenerator: (any PersistableEntityIdentifierGenerator)?
}

extension NexusSnapshot {
    /// An entity and its serializable components.
    public struct Member {
        /// The identifier of the entity.
        public let identifier: EntityIdentifier
        /// The serializable components of the entity that are not shared with an entity listed before it, sorted by type name.
        public let components: [any SerializableComponent]
        /// The component instances this entity shares with entities listed before it,
        /// keyed by component type name, with the identifier of the entity listing the instance in its ``components``.
        public let sharedComponents: [String: EntityIdentifier]
    }
}

extension NexusSnapshot {
    /// The coding keys of a snapshot.
    enum CodingKeys: String, CodingKey {
        case formatVersion
        case entityIdGenerator
        case entities
    }

    /// The coding keys of a snapshot member.
    enum MemberCodingKeys: String, CodingKey {
        case id
        case components
        case sharedComponents
    }
}

extension NexusSnapshot: Encodable {
    /// Encodes the snapshot.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding a component fails.
    /// - Complexity: O(E * C) where E is the number of entities and C the number of components per entity.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.formatVersion, forKey: .formatVersion)
        if let entityIdGenerator {
            try container.encode(entityIdGenerator, forKey: .entityIdGenerator)
        }
        var entities = container.nestedUnkeyedContainer(forKey: .entities)
        for member in members {
            var memberContainer = entities.nestedContainer(keyedBy: MemberCodingKeys.self)
            try memberContainer.encode(member.identifier, forKey: .id)
            var components = memberContainer.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .components)
            for component in member.components {
                let key = DynamicCodingKey(stringValue: type(of: component).componentTypeName).unsafelyUnwrapped
                try components.encode(component, forKey: key)
            }
            guard !member.sharedComponents.isEmpty else {
                continue
            }
            var sharedComponents = memberContainer.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .sharedComponents)
            for (typeName, owner) in member.sharedComponents.sorted(by: { $0.key < $1.key }) {
                try sharedComponents.encode(owner, forKey: DynamicCodingKey(stringValue: typeName).unsafelyUnwrapped)
            }
        }
    }
}
