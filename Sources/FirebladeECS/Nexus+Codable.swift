//
//  Nexus+Codable.swift
//
//
//  Created by Christian Treffs on 14.07.20.
//

extension CodingUserInfoKey {
    /// A user info key for providing the ``SerializableComponent`` types to register while decoding a ``Nexus``.
    ///
    /// The value must be an `[any SerializableComponent.Type]`.
    public static let nexusComponentTypes = CodingUserInfoKey(rawValue: "nexusComponentTypes").unsafelyUnwrapped

    /// A user info key for providing the ``NonSerializableComponentHandling`` while encoding a ``Nexus``.
    ///
    /// Defaults to ``NonSerializableComponentHandling/throwError`` if not provided.
    public static let nexusNonSerializableComponentHandling = CodingUserInfoKey(rawValue: "nexusNonSerializableComponentHandling").unsafelyUnwrapped
}

extension Nexus: Encodable {
    /// Encodes all entities, their serializable components and the entity identifier generator state as a ``NexusSnapshot``.
    ///
    /// Components that are not serializable are treated according to `encoder.userInfo[.nexusNonSerializableComponentHandling]`,
    /// which defaults to ``NonSerializableComponentHandling/throwError``.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: ``ComponentSerializationError`` or encoding errors.
    /// - Complexity: O(E * C log C) where E is the number of entities and C the number of components per entity.
    public func encode(to encoder: Encoder) throws {
        let handling = encoder.userInfo[.nexusNonSerializableComponentHandling] as? NonSerializableComponentHandling ?? .throwError
        try makeSnapshot(handling: handling).encode(to: encoder)
    }
}

extension Nexus: Decodable {
    /// Creates a nexus from an encoded ``NexusSnapshot``, keeping the encoded entity identifiers
    /// and the entity identifier generator state.
    ///
    /// The component types of the snapshot must be provided via `decoder.userInfo[.nexusComponentTypes]`.
    /// Components with ``Entity`` properties additionally require an ``EntityReferenceResolver``
    /// via `decoder.userInfo[.nexusEntityResolver]`; it is bound to the decoded nexus.
    /// Properties of type ``EntityIdentifier`` need no resolver, since identifiers are preserved.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: ``ComponentRegistryError``, ``ComponentSerializationError`` or decoding errors.
    /// - Complexity: O(E * C) where E is the number of entities and C the number of components per entity.
    public convenience init(from decoder: Decoder) throws {
        self.init()
        if let componentTypes = decoder.userInfo[.nexusComponentTypes] as? [any SerializableComponent.Type] {
            try register(componentTypes.map { $0 as any RegistrableComponent.Type })
        }
        let resolver = decoder.userInfo[.nexusEntityResolver] as? EntityReferenceResolver ?? EntityReferenceResolver(mapping: [:])
        resolver.bind(to: self)
        resolver.preservesIdentity = true
        _ = try NexusSnapshot.Import(from: decoder, resolver: resolver)
    }
}
