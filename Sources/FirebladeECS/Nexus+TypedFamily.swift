//
//  Nexus+TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public extension Nexus {

    func family<A, B, C>(requiresAll componentA: A.Type,
                         _ componentB: B.Type,
                         _ componentC: C.Type,
                         excludesAll excludedComponents: Component.Type...) -> TypedFamily<A, B, C> where A: Component, B: Component, C: Component {
        return TypedFamily(self,
                           requiresAll: componentA,
                           componentB,
                           componentC,
                           excludesAll: excludedComponents)
    }

}
