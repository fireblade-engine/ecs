//
//  ComponentIdentifier.swift
//  
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier {
    @usableFromInline let objectIdentifier: ObjectIdentifier

    init<T>(_ type: T.Type) where T: Component {
        self.objectIdentifier = ObjectIdentifier(type)
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
