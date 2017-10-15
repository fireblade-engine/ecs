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
	public static var identifier: ComponentIdentifier { return ComponentIdentifier(Self.self) }
	/// Uniquely identifies the component by its meta type
	public var identifier: ComponentIdentifier { return Self.identifier }
}

// MARK: - entity component hashable
public extension Component {

	/// Provides XOR hash value from component identifier (aka type) and entity index.
	/// Is only stable for app runtime.
	///
	/// - Parameter entityIdx: entity index
	/// - Returns: combinded entity component hash
	static func hashValue(using entityIdx: EntityIndex) -> EntityComponentHash {
		return Self.identifier.hashValue(using: entityIdx)
	}

	/// Provides XOR hash value from component identifier (aka type) and entity index.
	/// Is only stable for app runtime.
	///
	/// - Parameter entityIdx: entity index
	/// - Returns: combinded entity component hash
	func hashValue(using entityIdx: EntityIndex) -> EntityComponentHash {
		return Self.hashValue(using: entityIdx)
	}
}
