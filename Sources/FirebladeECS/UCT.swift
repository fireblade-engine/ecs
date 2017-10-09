//
//  UCT.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: Unique Component Type
/// Unique Component Type
public struct UCT {
	let objectIdentifier: ObjectIdentifier
	let type: Component.Type

	init(_ componentType: Component.Type) {
		objectIdentifier = ObjectIdentifier(componentType)
		type = componentType
	}

	init(_ component: Component) {
		let componentType: Component.Type = component.uct.type
		self.init(componentType)
	}
}

extension UCT: Equatable {
	public static func ==(lhs: UCT, rhs: UCT) -> Bool {
		return lhs.objectIdentifier == rhs.objectIdentifier
	}
}

extension UCT: Hashable {
	public var hashValue: Int {
		return objectIdentifier.hashValue
	}
}

// MARK: Unique Component Identifiable
public protocol UniqueComponentIdentifiable {
	static var uct: UCT { get }
	var uct: UCT { get }
}
