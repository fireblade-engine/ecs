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

        /// The runtime identifiers of registered component types by their stable type name.
        private(set) var identifiersByTypeName: [String: ComponentIdentifier] = [:]

        /// Registers a component type.
        ///
        /// Registering an already registered type has no effect.
        /// - Parameter type: The component type to register.
        /// - Returns: The record describing the registered type.
        /// - Throws: ``ComponentRegistryError/duplicateTypeName(_:)`` if a different type is already registered under the same name.
        /// - Complexity: O(1)
        @discardableResult
        mutating func register(_ type: any RegistrableComponent.Type) throws -> ComponentTypeRecord {
            if let existing = recordsByIdentifier[type.identifier] {
                return existing
            }
            let record = ComponentTypeRecord(type)
            guard identifiersByTypeName[record.typeName] == nil else {
                throw ComponentRegistryError.duplicateTypeName(record.typeName)
            }
            recordsByIdentifier[record.identifier] = record
            identifiersByTypeName[record.typeName] = record.identifier
            return record
        }

        /// Returns the record of the component type registered under the given name.
        /// - Parameter typeName: The stable component type name.
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
