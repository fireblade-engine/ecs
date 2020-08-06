//
//  ComponentIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier {
    @usableFromInline
    typealias Hash = Int
    @usableFromInline
    typealias StableId = UInt64

    @usableFromInline let hash: Hash
}

extension ComponentIdentifier {
    @usableFromInline
    init<C>(_ componentType: C.Type) where C: Component {
        self.hash = Self.makeRuntimeHash(componentType)
    }

    /// object identifier hash (only stable during runtime) - arbitrary hash is ok.
    internal static func makeRuntimeHash<C>(_ componentType: C.Type) -> Hash where C: Component {
        ObjectIdentifier(componentType).hashValue
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
