//
//  UEI.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.17.
//

// MARK: Unique Entity Index

public typealias UEI = UInt32 // provides 4294967295 unique identifiers

public extension UEI {

	private static var currentUEI: UEI = UInt32.min // starts at 0

	/// Provides the next (higher/free) unique entity identifer.
	/// Minimum: 1, maximum: 4294967295.
	/// - Returns: next higher unique entity identifer.
	public static var next: UEI {
		currentUEI += 1
		return currentUEI
	}

	internal static func free(_ uei: UEI) {
		// TODO: free used index
	}
}

// MARK: Unique Entity Identifiable
public protocol UniqueEntityIdentifiable: Hashable {
	var uei: UEI { get }
}

public extension UniqueEntityIdentifiable {
	public var hashValue: Int { return uei.hashValue }
}
