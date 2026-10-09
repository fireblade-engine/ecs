//
//  ComponentSerializationError.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Errors raised while exporting or importing nexus snapshots.
public enum ComponentSerializationError: Error, Equatable, Sendable {
    /// A component of the given type does not conform to ``SerializableComponent``.
    case notSerializable(typeName: String)
    /// A snapshot was decoded without an import context provided by the nexus,
    /// or the decoder's `userInfo` cannot store the import context.
    case missingImportContext
    /// The snapshot was written in a newer format version than ``NexusSnapshot/formatVersion``.
    case unsupportedFormatVersion(UInt)
    /// A snapshot can only be restored into a nexus without entities.
    case nexusNotEmpty
    /// The entity identifier generator did not provide the identifier of a restored entity.
    ///
    /// The generator's `init(startProviding:)` must provide the given identifiers in last out order.
    case entityIdentifierMismatch(expected: EntityIdentifier, actual: EntityIdentifier)
}
