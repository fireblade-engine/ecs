//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: class, UniqueComponentIdentifiable, Activatable {}

// MARK: UCI
extension Component {
	/// Uniquely identifies the component by its meta type
	public static var identifier: ComponentIdentifier { return ComponentIdentifier(Self.self) }
	/// Uniquely identifies the component by its meta type
	public var identifier: ComponentIdentifier { return Self.identifier }
}

// MARK: - activatable protocol
extension Component {
	public func activate() { /* default does nothing */ }
	public func deactivate() { /* default does nothing */ }
}

// MARK: - entity component hashable
internal extension Component {

	/// Provides XOR hash value from component identifier (aka type) and entity index.
	/// Is only stable for app runtime.
	///
	/// - Parameter entityIdx: entity index
	/// - Returns: combinded entity component hash
	internal static func hashValue(using entityIdx: EntityIndex) -> EntityComponentHash {
		return Self.identifier.hashValue(using: entityIdx)
	}

	/// Provides XOR hash value from component identifier (aka type) and entity index.
	/// Is only stable for app runtime.
	///
	/// - Parameter entityIdx: entity index
	/// - Returns: combinded entity component hash
	internal func hashValue(using entityIdx: EntityIndex) -> EntityComponentHash {
		return Self.hashValue(using: entityIdx)
	}
}
