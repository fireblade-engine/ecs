//
//  ComponentIdentifier.swift
//
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier {
    @usableFromInline
    typealias Hash = Int
    @usableFromInline
    typealias StableId = UInt

    @usableFromInline let hash: Hash
}

extension ComponentIdentifier {
    @usableFromInline
    init<C>(_ componentType: C.Type) where C: Component {
        self.hash = Nexus.makeOrGetComponentId(componentType)
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
