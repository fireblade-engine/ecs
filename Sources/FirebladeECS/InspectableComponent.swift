//
//  InspectableComponent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// A component that describes its stored properties for generic inspection, e.g. by editors or diff tools.
public protocol InspectableComponent: Component {
    /// The stored properties of this component type, in declaration order.
    static var componentProperties: [ComponentProperty<Self>] { get }
}

extension InspectableComponent {
    /// The current values of all stored properties, in declaration order.
    ///
    /// Use this type-erased view to inspect components of unknown concrete type.
    /// - Complexity: O(P) where P is the number of properties.
    public var inspectedProperties: [InspectedComponentProperty] {
        Self.componentProperties.map { property in
            InspectedComponentProperty(
                name: property.name,
                valueType: property.valueType,
                value: property.value(of: self),
                isWritable: property.isWritable
            )
        }
    }
}
