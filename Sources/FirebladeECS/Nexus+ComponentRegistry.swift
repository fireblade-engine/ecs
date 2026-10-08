//
//  Nexus+ComponentRegistry.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Nexus {
    /// Registers a component type.
    ///
    /// Registering an already registered type has no effect.
    /// - Parameter type: The component type to register.
    /// - Returns: The record describing the registered type.
    /// - Throws: ``ComponentRegistryError/duplicateTypeName(_:)`` if a different type is already registered under the same name.
    /// - Complexity: O(1)
    @discardableResult
    public final func register(_ type: any RegistrableComponent.Type) throws -> ComponentTypeRecord {
        try componentRegistry.register(type)
    }

    /// Registers multiple component types.
    /// - Parameter types: The component types to register.
    /// - Throws: ``ComponentRegistryError/duplicateTypeName(_:)`` if a different type is already registered under the same name.
    ///   Types preceding the conflicting type remain registered.
    /// - Complexity: O(N) where N is the number of types.
    public final func register(_ types: [any RegistrableComponent.Type]) throws {
        for type in types {
            try componentRegistry.register(type)
        }
    }

    /// All registered component types, sorted by type name.
    /// - Complexity: O(T log T) where T is the number of registered types.
    public final var registeredComponentTypes: [ComponentTypeRecord] {
        componentRegistry.recordsByIdentifier.values.sorted { $0.typeName < $1.typeName }
    }

    /// Returns the component type registered under the given name.
    /// - Parameter typeName: The stable component type name.
    /// - Returns: The record if a type is registered under the name; otherwise, `nil`.
    /// - Complexity: O(1)
    public final func componentType(named typeName: String) -> ComponentTypeRecord? {
        componentRegistry.record(named: typeName)
    }

    /// Returns the registered component type with the given runtime identifier.
    /// - Parameter identifier: The runtime component identifier.
    /// - Returns: The record if the type is registered; otherwise, `nil`.
    /// - Complexity: O(1)
    public final func componentType(for identifier: ComponentIdentifier) -> ComponentTypeRecord? {
        componentRegistry.recordsByIdentifier[identifier]
    }

    /// Checks whether a component type is registered.
    /// - Parameter type: The component type.
    /// - Returns: `true` if the type is registered; otherwise, `false`.
    /// - Complexity: O(1)
    public final func isRegistered(_ type: any Component.Type) -> Bool {
        componentRegistry.recordsByIdentifier[type.identifier] != nil
    }

    /// Registers the type of a component instance on its first assignment, if it is registrable.
    ///
    /// A name conflict is reported as a non-fatal error to the delegate.
    /// - Parameter componentType: The type of the assigned component.
    /// - Complexity: O(1)
    func registerOnFirstAssignment(_ componentType: any Component.Type) {
        guard let registrableType = componentType as? any RegistrableComponent.Type else {
            return
        }
        do {
            try componentRegistry.register(registrableType)
        } catch {
            delegate?.nexusNonFatalError("ComponentRegistry failure: could not register \(componentType): \(error)")
        }
    }
}
