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
    /// A snapshot was decoded without an import context provided by the nexus.
    case missingImportContext
}
