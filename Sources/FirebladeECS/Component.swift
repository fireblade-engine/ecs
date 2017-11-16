//
//  Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public protocol Component: class, TypeIdentifiable {}
public typealias ComponentIdentifier = ObjectIdentifier

public extension Component {
	var identifier: ComponentIdentifier { return typeObjectIdentifier }
	static var identifier: ComponentIdentifier { return typeObjectIdentifier }
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

// MARK: - component identifier hashable
extension ComponentIdentifier {

	/// Provides XOR hash value from component identifier (aka type) and entity index.
	/// Is only stable for app runtime.
	///
	/// - Parameter entityIdx: entity index
	/// - Returns: combinded entity component hash
	func hashValue(using entityIdx: EntityIndex) -> EntityComponentHash {
		return hashValue(using: entityIdx.identifier)
	}

	func hashValue(using entityId: EntityIdentifier) -> EntityComponentHash {
		return EntityComponentHash.compose(entityId: entityId, componentTypeHash: hashValue)
	}
}
