//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

public typealias EntityIdentifier = UInt32 // provides 4294967295 unique identifiers
public typealias EntityIndex = Int

public extension EntityIdentifier {
	static let invalid = EntityIdentifier.max
}

public extension EntityIdentifier {
	var index: EntityIndex {
		return EntityIndex(self)
	}
}

public extension EntityIndex {
	var identifier: EntityIdentifier {
		return EntityIdentifier(truncatingIfNeeded: self)
	}
}

// MARK: Unique Entity Identifiable
public protocol UniqueEntityIdentifiable: Hashable {
	var identifier: EntityIdentifier { get }
}

public extension UniqueEntityIdentifiable {
	var hashValue: Int { return identifier.hashValue }
}
