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

extension InstanceHashable {
	public var instanceObjectIdentifier: ObjectIdentifier { return ObjectIdentifier.init(self) }
	public static func == (lhs: Self, rhs: Self) -> Bool { return lhs.hashValue == rhs.hashValue }
	public var hashValue: Int { return instanceObjectIdentifier.hashValue }
}

extension TypeIdentifiable {
	public static var typeObjectIdentifier: ObjectIdentifier { return ObjectIdentifier.init(Self.self) }
	public var typeObjectIdentifier: ObjectIdentifier { return Self.typeObjectIdentifier }
}

extension TypeHashable {
	public static func == (lhs: Self, rhs: Self) -> Bool { return lhs.hashValue == rhs.hashValue }
	public var hashValue: Int { return typeObjectIdentifier.hashValue }
	public static var hashValue: Int { return typeObjectIdentifier.hashValue }
}

extension TypeHashable where Self: InstanceHashable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.typeObjectIdentifier == rhs.typeObjectIdentifier &&
			lhs.instanceObjectIdentifier == rhs.instanceObjectIdentifier
	}
	public var hashValue: Int {
		return typeObjectIdentifier.hashValue ^ instanceObjectIdentifier.hashValue // TODO: this might not be best - use hash combine?
	}
}
