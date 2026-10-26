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

    private let assign: ((inout Root, Any) -> Bool)?

    /// Creates a property description.
    /// - Parameters:
    ///   - name: The name of the property.
    ///   - keyPath: The key path to the property.
    public init<Value>(name: String, keyPath: KeyPath<Root, Value>) {
        self.name = name
        valueType = Value.self
        self.keyPath = keyPath
        if let writable = keyPath as? WritableKeyPath<Root, Value> {
            isWritable = true
            assign = { root, newValue in
                guard let typed = newValue as? Value else {
                    return false
                }
                root[keyPath: writable] = typed
                return true
            }
        } else {
            isWritable = false
            assign = nil
        }
    }

    /// Returns the current value of the property.
    /// - Parameter component: The component to read the value from.
    /// - Returns: The current value.
    /// - Complexity: O(1)
    public func value(of component: Root) -> Any {
        component[keyPath: keyPath]
    }
}

extension ComponentProperty {
    /// Writes a value to the property of a component.
    ///
    /// Components are value types, so write to a copy and store it back, e.g. with ``Entity/modify(_:_:)``.
    /// - Parameters:
    ///   - value: The new value. It must be of the property's ``valueType``.
    ///   - component: The component to write to.
    /// - Returns: `true` if the value was written; `false` if the property is read-only or the value has the wrong type.
    /// - Complexity: O(1)
    @discardableResult
    public func set(_ value: Any, on component: inout Root) -> Bool {
        assign?(&component, value) ?? false
    }
}
