//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: AnyObject, TypeIdentifiable {}
public typealias ComponentIdentifier = ObjectIdentifier

public extension Component {
	var identifier: ComponentIdentifier { return typeObjectIdentifier }
	static var identifier: ComponentIdentifier { return typeObjectIdentifier }
}

/// TypeIdentifiable
/// Identifies an object by it's meta type.
public protocol TypeIdentifiable {
    static var typeObjectIdentifier: ObjectIdentifier { get }
    var typeObjectIdentifier: ObjectIdentifier { get }
}

public extension TypeIdentifiable {
    static var typeObjectIdentifier: ObjectIdentifier { return ObjectIdentifier(Self.self) }

    var typeObjectIdentifier: ObjectIdentifier { return Self.typeObjectIdentifier }
}
