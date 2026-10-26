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
    /// Unique, immutable identifier of this component type.
    static var identifier: ComponentIdentifier { get }

    /// Unique, immutable identifier of this component type.
    var identifier: ComponentIdentifier { get }

    /// The dense index of this component type, see ``Component/componentIndex``.
    ///
    /// Two component types must never share an index. A default implementation assigns indices lazily.
    static var componentIndex: Int { get }
}

extension Component {
    /// The unique identifier for this component type.
    /// - Complexity: O(1)
    public static var identifier: ComponentIdentifier {
        ComponentIdentifier(Self.self)
    }

    /// The unique identifier for this component instance.
    /// - Complexity: O(1)
    @inline(__always)
    public var identifier: ComponentIdentifier {
        Self.identifier
    }
}
