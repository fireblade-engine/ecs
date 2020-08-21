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
    @usableFromInline
    init<C>(_ componentType: C.Type) where C: Component {
        self.id = Self.makeRuntimeHash(componentType)
    }

    /// object identifier hash (only stable during runtime) - arbitrary hash is ok.
    internal static func makeRuntimeHash<C>(_ componentType: C.Type) -> Identifier where C: Component {
        ObjectIdentifier(componentType).hashValue
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
