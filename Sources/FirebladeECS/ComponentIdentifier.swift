//
//  ComponentIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier {
    public typealias Identifier = Int
    public let id: Identifier
}

extension ComponentIdentifier {
    /// Initializes a component identifier for a given component type.
    /// - Parameter componentType: The type of the component.
    /// - Complexity: O(1)
    @usableFromInline
    init(_ componentType: (some Component).Type) {
        id = Self.makeRuntimeHash(componentType)
    }

    /// Creates a runtime-stable hash for a component type.
    ///
    /// This hash is based on the `ObjectIdentifier` of the component's meta type.
    /// While it is stable for the duration of the process, it may change between different runs.
    /// - Parameter componentType: The component type to hash.
    /// - Returns: A unique identifier for the component type.
    /// - Complexity: O(1)
    static func makeRuntimeHash(_ componentType: (some Component).Type) -> Identifier {
        ObjectIdentifier(componentType).hashValue
    }
}

extension ComponentIdentifier: Equatable {}
extension ComponentIdentifier: Hashable {}
extension ComponentIdentifier: Sendable {}
