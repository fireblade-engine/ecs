//
//  ComponentTypeRecord.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Describes a component type registered in a ``Nexus``.
public struct ComponentTypeRecord {
    /// The registered component type.
    public let type: any RegistrableComponent.Type

    /// The stable, unique name of the component type.
    public let typeName: String

    /// The stable identifier of the component type.
    public let stableIdentifier: StableComponentIdentifier

    /// The runtime identifier of the component type.
    public let identifier: ComponentIdentifier

    /// Creates a record describing a component type.
    /// - Parameter type: The component type.
    /// - Complexity: O(N) where N is the length of the type name.
    init(_ type: any RegistrableComponent.Type) {
        self.type = type
        typeName = type.componentTypeName
        stableIdentifier = type.stableIdentifier
        identifier = type.identifier
    }
}

extension ComponentTypeRecord {
    /// Indicates whether the component type can be default initialized.
    public var isDefaultInitializable: Bool {
        type is any DefaultInitializable.Type
    }
}

extension ComponentTypeRecord: Sendable {}

extension ComponentTypeRecord {
    /// Indicates whether the component type can be cloned.
    public var isCloneable: Bool {
        type is any CloneableComponent.Type
    }
}
