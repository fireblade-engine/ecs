//
//  CodingStrategy.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

/// A strategy for determining coding keys for components during encoding and decoding.
public protocol CodingStrategy: Sendable {
    /// Returns the coding key to use for a specific component type.
    /// - Parameter componentType: The type of the component.
    /// - Returns: The dynamic coding key to use.
    func codingKey<C: Component>(for componentType: C.Type) -> DynamicCodingKey
}

/// A dynamic coding key that can be initialized with an integer or a string.
///
/// This type conforms to `CodingKey` and is used to provide flexible keys for encoding and decoding.
public struct DynamicCodingKey: CodingKey, Sendable {
    /// The integer value of the coding key, if any.
    public var intValue: Int?
    /// The string value of the coding key.
    public var stringValue: String

    /// Creates a new coding key from an integer value.
    /// - Parameter intValue: The integer value.
    public init?(intValue: Int) {
        self.intValue = intValue; stringValue = "\(intValue)"
    }

    /// Creates a new coding key from a string value.
    /// - Parameter stringValue: The string value.
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
}
