//
//  InspectedComponentProperty.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// A type-erased snapshot of a component property and its current value.
public struct InspectedComponentProperty {
    /// The name of the property.
    public let name: String
    /// The type of the property value.
    public let valueType: Any.Type
    /// The value of the property at the time of inspection.
    public let value: Any
    /// Indicates whether the property is writable.
    public let isWritable: Bool
}
