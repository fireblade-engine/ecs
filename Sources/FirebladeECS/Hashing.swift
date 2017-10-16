//
//  Hashing.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 16.10.17.
//

extension EntityComponentHash {

	static func compose(entityId: EntityIdentifier, componentTypeHash: ComponentTypeHash) -> EntityComponentHash {
		let entityIdSwapped: UInt = UInt(entityId).byteSwapped // needs to be 64 bit
		let componentTypeHashUInt: UInt = UInt(bitPattern: componentTypeHash)
		let hashUInt: UInt =  componentTypeHashUInt ^ entityIdSwapped
		return Int(bitPattern: hashUInt)
	}

	static func decompose(_ hash: EntityComponentHash, with entityId: EntityIdentifier) -> ComponentTypeHash {
		let entityIdSwapped: UInt = UInt(entityId).byteSwapped
		let entityIdSwappedInt = Int(bitPattern: entityIdSwapped)
		return hash ^ entityIdSwappedInt
	}

	static func decompose(_ hash: EntityComponentHash, with componentTypeHash: ComponentTypeHash) -> EntityIdentifier {
		let entityId: Int = (hash ^ componentTypeHash).byteSwapped
		return EntityIdentifier(truncatingIfNeeded: entityId)
	}
}
