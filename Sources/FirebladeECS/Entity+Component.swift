//
//  Entity+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.10.17.
//

extension Entity {
    @inlinable
    public func get<C>() -> C? where C: Component {
        nexus.get(for: identifier)
    }

    @inlinable
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        nexus.get(for: identifier)
    }

    @inlinable
    public func get<A, B>(components _: A.Type, _: B.Type) -> (A?, B?) where A: Component, B: Component {
        let compA: A? = get(component: A.self)
        let compB: B? = get(component: B.self)
        return (compA, compB)
    }

    // swiftlint:disable large_tuple
    @inlinable
    public func get<A, B, C>(components _: A.Type, _: B.Type, _: C.Type) -> (A?, B?, C?) where A: Component, B: Component, C: Component {
        let compA: A? = get(component: A.self)
        let compB: B? = get(component: B.self)
        let compC: C? = get(component: C.self)
        return (compA, compB, compC)
    }

    @inlinable
    public subscript<C: Component, Value>(_ componentKeyPath: WritableKeyPath<C, Value>) -> Value? {
        nonmutating set {
            guard var comp = self.get(component: C.self),
                let value = newValue else {
                    return
            }
            comp[keyPath: componentKeyPath] = value
        }
        get {
            self.get(component: C.self)?[keyPath: componentKeyPath]
        }
    }

    @inlinable
    public subscript<C: Component>(_ componentType: C.Type) -> C? {
        self.get(component: componentType)
    }
}
