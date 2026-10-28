//
//  ComponentCloneError.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Errors raised while cloning entities.
public enum ComponentCloneError: Error, Equatable, Sendable {
    /// The entity does not exist in the nexus.
    case unknownEntity(EntityIdentifier)
    /// A component of the given type does not conform to ``CloneableComponent``.
    case notCloneable(typeName: String)
}
