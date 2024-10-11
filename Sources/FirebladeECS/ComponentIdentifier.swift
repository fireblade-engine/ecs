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
    init(_ componentType: (some Component).Type) {
        id = Self.makeRuntimeHash(componentType)
    }

    /// object identifier hash (only stable during runtime) - arbitrary hash is ok.
    static func makeRuntimeHash(_ componentType: (some Component).Type) -> Identifier {
        ObjectIdentifier(componentType).hashValue
    }
}

extension ComponentIdentifier: Equatable {}
extension ComponentIdentifier: Hashable {}
