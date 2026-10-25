//
//  RegistrableComponent.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// A component type that can be registered in the component registry of a ``Nexus``.
///
/// Registered component types are known to the nexus by their stable ``componentTypeName``,
/// which allows querying, importing and exporting component types without holding instances.
///
/// A registrable component type is registered automatically the first time an instance
/// is assigned to an entity. Register types explicitly via `Nexus.register(_:)`
/// before decoding data that references them.
public protocol RegistrableComponent: Component {
    /// The stable, unique name of this component type.
    ///
    /// Defaults to the fully qualified type name (e.g. `MyGame.Position`), which is stable
    /// across process launches for types declared at file scope or nested in other types.
    /// Provide an explicit name to keep persisted data valid when renaming or moving the type.
    static var componentTypeName: String { get }

    /// Former names of this component type that are still accepted when decoding.
    ///
    /// Add the previous ``componentTypeName`` here after renaming or moving a type,
    /// so that data persisted under the old name keeps loading. Encoding always uses ``componentTypeName``.
    static var componentTypeNameAliases: [String] { get }
}

extension RegistrableComponent {
    /// The fully qualified type name of this component type.
    /// - Complexity: O(1)
    public static var componentTypeName: String {
        String(reflecting: Self.self)
    }

    /// No former names.
    /// - Complexity: O(1)
    public static var componentTypeNameAliases: [String] {
        []
    }

    /// The stable identifier of this component type, derived from ``componentTypeName``.
    /// - Complexity: O(N) where N is the length of the type name.
    public static var stableIdentifier: StableComponentIdentifier {
        StableComponentIdentifier(typeName: componentTypeName)
    }

    /// Registers this component type in the given nexus.
    /// - Parameter nexus: The nexus to register this component type in.
    /// - Throws: ``ComponentRegistryError/duplicateTypeName(_:)`` if a different type is already registered under the same name.
    /// - Complexity: O(1)
    public static func register(in nexus: Nexus) throws {
        try nexus.register(Self.self)
    }
}
