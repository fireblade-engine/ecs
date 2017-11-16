//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: class, TypeIdentifiable {}

extension Component {
	public var identifier: ComponentIdentifier { return typeObjectIdentifier }
	public static var identifier: ComponentIdentifier { return typeObjectIdentifier }
}

// MARK: - activatable protocol
extension Component {
	public func activate() { /* default does nothing */ }
	public func deactivate() { /* default does nothing */ }
}

// MARK: - entity component hashable
extension Component {

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
