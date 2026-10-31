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

    /// Indicates whether the component type can be cloned.
    public var isCloneable: Bool {
        type is any CloneableComponent.Type
    }

    /// Indicates whether the component type can be encoded and decoded.
    public var isSerializable: Bool {
        type is any SerializableComponent.Type
    }

    /// Indicates whether the component type describes its stored properties.
    public var isInspectable: Bool {
        type is any InspectableComponent.Type
    }
}

extension ComponentTypeRecord: Sendable {}

extension ComponentTypeRecord {
    /// A record with the names it is registered under, computed once per type and process.
    ///
    /// Deriving the record reflects the type name twice and hashes it; every nexus registers each type on its first
    /// assignment, so the result is shared instead. The type name and its aliases are constants of a type.
    struct Cached: Sendable {
        let record: ComponentTypeRecord
        /// The type name followed by the aliases that differ from it.
        let names: [String]
    }

    private final class Cache: @unchecked Sendable {
        let lock = Nexus.Lock()
        var entries: [ComponentIdentifier: Cached] = [:]
    }

    private static let cache = Cache()

    /// The record of `type` and its registration names; computed on first request in the process.
    /// - Complexity: O(1) amortized.
    static func cached(_ type: any RegistrableComponent.Type) -> Cached {
        let identifier = type.identifier
        if let hit = cache.lock.withLock({ cache.entries[identifier] }) {
            return hit
        }
        let record = ComponentTypeRecord(type)
        let entry = Cached(record: record, names: [record.typeName] + type.componentTypeNameAliases.filter { $0 != record.typeName })
        return cache.lock.withLock {
            if let raced = cache.entries[identifier] {
                return raced
            }
            cache.entries[identifier] = entry
            return entry
        }
    }
}
