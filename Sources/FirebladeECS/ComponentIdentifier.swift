//
//  ComponentIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public typealias ComponentIdentifier = ObjectIdentifier

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
