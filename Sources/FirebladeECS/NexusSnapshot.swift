//
//  NexusSnapshot.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// An encodable view of the entities of a nexus and their serializable components.
///
/// A snapshot references the live component instances of the nexus. Encode it right after creation.
///
/// The encoded form starts with the ``formatVersion`` and lists all entities in ascending identifier order,
/// each with its original identifier and its components keyed by their stable ``RegistrableComponent/componentTypeName``:
/// ```json
/// { "formatVersion": 1, "entities": [ { "id": 0, "components": { "MyGame.Position": { "x": 1, "y": 2 } } } ] }
/// ```
public struct NexusSnapshot {
    /// The version of the encoded snapshot format written by this library.
    ///
    /// Additions to the format, such as entity identifier generator state, increase the version.
    /// Decoding rejects snapshots with a newer version.
    public static let formatVersion: UInt = 1

    /// The entities of the snapshot in ascending identifier order.
    public let members: [Member]
}

extension NexusSnapshot {
    /// An entity and its serializable components.
    public struct Member {
        /// The identifier of the entity.
        public let identifier: EntityIdentifier
        /// The serializable components of the entity, sorted by type name.
        public let components: [any SerializableComponent]
    }
}

extension NexusSnapshot {
    /// The coding keys of a snapshot.
    enum CodingKeys: String, CodingKey {
        case formatVersion
        case entities
    }

    /// The coding keys of a snapshot member.
    enum MemberCodingKeys: String, CodingKey {
        case id
        case components
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
        var entities = container.nestedUnkeyedContainer(forKey: .entities)
        for member in members {
            var memberContainer = entities.nestedContainer(keyedBy: MemberCodingKeys.self)
            try memberContainer.encode(member.identifier, forKey: .id)
            var components = memberContainer.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .components)
            for component in member.components {
                let key = DynamicCodingKey(stringValue: type(of: component).componentTypeName).unsafelyUnwrapped
                try components.encode(component, forKey: key)
            }
        }
    }
}
