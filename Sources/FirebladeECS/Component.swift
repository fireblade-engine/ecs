//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: UniqueComponentIdentifiable {}

// MARK: UCI
extension Component {
	/// Uniquely identifies the component by its meta type
	public static var uct: UCT { return UCT(Self.self) }
	/// Uniquely identifies the component by its meta type
	public var uct: UCT { return Self.uct }
}

// MARK: Equatable
public func ==<A: Component, B: Component>(lhs: A, rhs: B) -> Bool {
	return A.uct == B.uct
}
