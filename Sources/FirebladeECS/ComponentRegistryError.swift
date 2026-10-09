//
//  ComponentRegistryError.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Errors raised by the component registry of a ``Nexus``.
public enum ComponentRegistryError: Error, Equatable, Sendable {
    /// A different component type is already registered under the given type name.
    case duplicateTypeName(String)
    /// No component type is registered under the given type name.
    case unknownTypeName(String)
}
