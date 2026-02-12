//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Component**
///
/// A component represents the raw data for one aspect of an entity.
public protocol Component: AnyObject, Sendable {
    // Unique, immutable identifier of this component type.    static var identifier: ComponentIdentifier { get }

    /// Unique, immutable identifier of this component type.
    var identifier: ComponentIdentifier { get }
}

extension Component {
    /// The unique identifier for this component type.
    public static var identifier: ComponentIdentifier {
        ComponentIdentifier(Self.self)
    }

    /// The unique identifier for this component instance.
    @inline(__always)
    public var identifier: ComponentIdentifier {
        Self.identifier
    }
}
