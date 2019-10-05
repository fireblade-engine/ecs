//
//  ComponentIdentifier.swift
//
//
//  Created by Christian Treffs on 20.08.19.
//

/// Identifies a component by it's meta type
public struct ComponentIdentifier: Identifiable {
    public let id: String

    public init<T>(_ componentType: T.Type) where T: Component {
        defer { Nexus.register(component: T.self, using: self) }

        self.id = String(reflecting: componentType)
    }
}

extension ComponentIdentifier: Equatable { }
extension ComponentIdentifier: Hashable { }
extension ComponentIdentifier: Codable { }
extension ComponentIdentifier: Comparable {
    public static func < (lhs: ComponentIdentifier, rhs: ComponentIdentifier) -> Bool {
        return lhs.id < rhs.id
    }
}
