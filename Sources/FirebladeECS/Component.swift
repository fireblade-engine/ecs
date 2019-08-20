//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: class {
    static var identifier: ComponentIdentifier { get }
    var identifier: ComponentIdentifier { get }
}

public extension Component {
	static var identifier: ComponentIdentifier { return ComponentIdentifier(Self.self) }
    @inlinable var identifier: ComponentIdentifier { return Self.identifier }
}
