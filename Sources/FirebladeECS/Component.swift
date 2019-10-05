//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

/// **Component**
///
/// A component represents the raw data for one aspect of an object.
public protocol Component: class, Codable {
    static var identifier: ComponentIdentifier { get }
    var identifier: ComponentIdentifier { get }
}

extension Component {
    @inlinable public var identifier: ComponentIdentifier { return Self.identifier }
}
