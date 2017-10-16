//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: Unique Entity Index

public typealias EntityIdentifier = UInt32 // provides 4294967295 unique identifiers
public typealias EntityIndex = Int

public extension EntityIdentifier {
	static let invalid: EntityIdentifier = EntityIdentifier.max
}

public extension EntityIdentifier {
	public var index: EntityIndex {
		return EntityIndex(self)
	}
}

public extension EntityIndex {
	public var identifier: EntityIdentifier {
		return EntityIdentifier(truncatingIfNeeded: self)
	}
}

// MARK: Unique Entity Identifiable
public protocol UniqueEntityIdentifiable: Hashable {
	var identifier: EntityIdentifier { get }
}

public extension UniqueEntityIdentifiable {
	public var hashValue: Int { return identifier.hashValue }
}
