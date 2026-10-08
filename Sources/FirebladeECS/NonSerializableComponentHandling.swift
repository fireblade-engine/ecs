//
//  NonSerializableComponentHandling.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Defines how exporting a nexus snapshot treats components that are not serializable.
public enum NonSerializableComponentHandling: Sendable {
    /// Fail the export with ``ComponentSerializationError/notSerializable(typeName:)``.
    case throwError
    /// Leave non-serializable components out of the snapshot, e.g. runtime-only components.
    case skip
}
