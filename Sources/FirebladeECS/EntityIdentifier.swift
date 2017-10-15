//
//  EntityIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: Unique Entity Index

public typealias EntityIdentifier = UInt64 // provides 18446744073709551615 unique identifiers
public typealias EntityIndex = Int
public typealias EntityReuseCount = UInt32

public extension EntityIdentifier {
	static let invalid: EntityIdentifier = EntityIdentifier.max
}

public extension EntityIdentifier {
	public var index: EntityIndex { return EntityIndex(self & 0xffffffff) } // shifts entity identifier by UInt32.max
}

public extension EntityIndex {
	public var identifier: EntityIdentifier { return EntityIdentifier(self & -0xffffffff) } // shifts entity identifier by -UInt32.max
}


// MARK: Unique Entity Identifiable
public protocol UniqueEntityIdentifiable: Hashable {
	var identifier: EntityIdentifier { get }
}

public extension UniqueEntityIdentifiable {
	public var hashValue: Int { return identifier.hashValue }
}

