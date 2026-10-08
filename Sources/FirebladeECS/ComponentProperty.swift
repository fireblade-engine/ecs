//
//  ComponentProperty.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Describes a stored property of a component type.
public struct ComponentProperty<Root: Component> {
    /// The name of the property.
    public let name: String

    /// The type of the property value.
    public let valueType: Any.Type

    /// The key path to the property.
    public let keyPath: PartialKeyPath<Root>

    /// Indicates whether the property can be written through ``keyPath``.
    public let isWritable: Bool

    /// Creates a property description.
    /// - Parameters:
    ///   - name: The name of the property.
    ///   - keyPath: The key path to the property.
    public init<Value>(name: String, keyPath: KeyPath<Root, Value>) {
        self.name = name
        valueType = Value.self
        self.keyPath = keyPath
        isWritable = keyPath is ReferenceWritableKeyPath<Root, Value>
    }

    /// Returns the current value of the property.
    /// - Parameter component: The component to read the value from.
    /// - Returns: The current value.
    /// - Complexity: O(1)
    public func value(of component: Root) -> Any {
        component[keyPath: keyPath]
    }
}
