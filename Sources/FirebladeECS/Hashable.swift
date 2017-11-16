//
//  Hashable.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 04.11.17.
//

/// TypeIdentifiable
/// Identifies an object by it's meta type.
public protocol TypeIdentifiable {
	static var typeObjectIdentifier: ObjectIdentifier { get }
	var typeObjectIdentifier: ObjectIdentifier { get }
}

/// TypeHashable
/// Identifies an object by it's meta type and conforms to Hashable.
/// This introduces a Self type requirement.
public protocol TypeHashable: TypeIdentifiable, Hashable {
	static var hashValue: Int { get }
}

/// InstanceHashable
/// Identifies an object instance by it's object identifier and conforms to Hashable
public protocol InstanceHashable: class, Hashable {
	var instanceObjectIdentifier: ObjectIdentifier { get }
}

/// TypeInstanceHashable
/// Identifies an object by instance and meta type and conforms to Hashable
public typealias TypeInstanceHashable = TypeHashable & InstanceHashable

public extension InstanceHashable {
	var instanceObjectIdentifier: ObjectIdentifier { return ObjectIdentifier(self) }

	static func == (lhs: Self, rhs: Self) -> Bool { return lhs.hashValue == rhs.hashValue }

	var hashValue: Int { return instanceObjectIdentifier.hashValue }
}

public extension TypeIdentifiable {
	static var typeObjectIdentifier: ObjectIdentifier { return ObjectIdentifier(Self.self) }

	var typeObjectIdentifier: ObjectIdentifier { return Self.typeObjectIdentifier }
}

public extension TypeHashable {
	static func == (lhs: Self, rhs: Self) -> Bool { return lhs.hashValue == rhs.hashValue }

	var hashValue: Int { return typeObjectIdentifier.hashValue }
	static var hashValue: Int { return typeObjectIdentifier.hashValue }
}

public extension TypeHashable where Self: InstanceHashable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.typeObjectIdentifier == rhs.typeObjectIdentifier &&
			lhs.instanceObjectIdentifier == rhs.instanceObjectIdentifier
	}

	var hashValue: Int {
		return  hash(combine: typeObjectIdentifier.hashValue, instanceObjectIdentifier.hashValue)
	}
}
