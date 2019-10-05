//
//  ComponentIdentifier.swift
//
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier: Identifiable {
    public let id: ObjectIdentifier

    init<T>(_ type: T.Type) where T: Component {
        self.id = ObjectIdentifier(type)
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
