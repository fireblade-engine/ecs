//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Component**
///
/// A component represents the raw data for one aspect of an entity.
///
/// Components are value types (structs or enums). The nexus stores them by value, reading one returns a copy and
/// writes go through ``Entity/set(_:)-(Component)``, ``Entity/modify(_:_:)`` or the entity subscripts. Components with
/// handles that are not `Sendable` conform with `@unchecked Sendable`.
public protocol Component: Sendable {
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
