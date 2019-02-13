//
//  Nexus+TypedSingle.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.02.19.
//

public extension Nexus {
    func single<A>(
        requires componentA: A.Type,
        excludesAll excludedComponents: Component.Type...
        ) -> TypedSingle1<A> where A: Component {
        return TypedSingle1(
            self,
            requires: componentA,
            excludesAll: excludedComponents
        )
    }
}
