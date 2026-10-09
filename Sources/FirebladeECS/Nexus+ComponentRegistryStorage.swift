//
//  Nexus+ComponentRegistryStorage.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

extension Nexus {
    /// Keeps track of all component types known to a ``Nexus``.
    struct ComponentRegistry {
        /// The registered component types by their runtime identifier.
        private(set) var recordsByIdentifier: [ComponentIdentifier: ComponentTypeRecord] = [:]

        /// The runtime identifiers of registered component types by their stable type name and their aliases.
        private(set) var identifiersByTypeName: [String: ComponentIdentifier] = [:]

        /// Registers a component type.
        ///
        /// Registering an already registered type has no effect.
        /// - Parameter type: The component type to register.
        /// - Returns: The record describing the registered type.
        /// - Throws: ``ComponentRegistryError/duplicateTypeName(_:)`` if a different type is already registered under the same name or alias.
        /// - Complexity: O(A) where A is the number of type name aliases.
        @discardableResult
        mutating func register(_ type: any RegistrableComponent.Type) throws -> ComponentTypeRecord {
            if let existing = recordsByIdentifier[type.identifier] {
                return existing
            }
            let record = ComponentTypeRecord(type)
            let names = [record.typeName] + type.componentTypeNameAliases.filter { $0 != record.typeName }
            for name in names where identifiersByTypeName[name] != nil {
                throw ComponentRegistryError.duplicateTypeName(name)
            }
            recordsByIdentifier[record.identifier] = record
            for name in names {
                identifiersByTypeName[name] = record.identifier
            }
            return record
        }

        /// Returns the record of the component type registered under the given name or alias.
        /// - Parameter typeName: The stable component type name or one of its aliases.
        /// - Returns: The record if a type is registered under the name; otherwise, `nil`.
        /// - Complexity: O(1)
        func record(named typeName: String) -> ComponentTypeRecord? {
            guard let identifier = identifiersByTypeName[typeName] else {
                return nil
            }
            return recordsByIdentifier[identifier]
        }
    }
}
