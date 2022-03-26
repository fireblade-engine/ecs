//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Component**
///
/// A component represents the raw data for one aspect of an entity.
public protocol Component {
    /// Unique, immutable identifier of this component type.
    static var identifier: ComponentIdentifier { get }

    /// Unique, immutable identifier of this component type.
    var identifier: ComponentIdentifier { get }
}

extension Component {
    public static var identifier: ComponentIdentifier { ComponentIdentifier(Self.self) }
    @inline(__always)
    public var identifier: ComponentIdentifier { Self.identifier }
}
