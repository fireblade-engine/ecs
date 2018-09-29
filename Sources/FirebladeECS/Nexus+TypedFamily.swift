//
//  Nexus+TypedFamily.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 29.09.18.
//

public extension Nexus {

    func family<A>(requires componentA: A.Type,
                   excludesAll excludedComponents: Component.Type...) -> TypedFamily1<A> where A: Component {
        return TypedFamily1(self,
                            requiresAll: componentA,
                            excludesAll: excludedComponents)
    }

    func family<A, B>(requiresAll componentA: A.Type,
                      _ componentB: B.Type,
                      excludesAll excludedComponents: Component.Type...) -> TypedFamily2<A, B> where A: Component, B: Component {
        return TypedFamily2(self,
                            requiresAll: componentA,
                            componentB,
                            excludesAll: excludedComponents)
    }

    func family<A, B, C>(requiresAll componentA: A.Type,
                         _ componentB: B.Type,
                         _ componentC: C.Type,
                         excludesAll excludedComponents: Component.Type...) -> TypedFamily3<A, B, C> where A: Component, B: Component, C: Component {
        return TypedFamily3(self,
                            requiresAll: componentA,
                            componentB,
                            componentC,
                            excludesAll: excludedComponents)
    }

    func family<A, B, C, D>(requiresAll componentA: A.Type,
                            _ componentB: B.Type,
                            _ componentC: C.Type,
                            _ componentD: D.Type,
                            excludesAll excludedComponents: Component.Type...) -> TypedFamily4<A, B, C, D> where A: Component, B: Component, C: Component, D: Component {
        return TypedFamily4(self,
                            requiresAll: componentA,
                            componentB,
                            componentC,
                            componentD,
                            excludesAll: excludedComponents)
    }

    // swiftlint:disable function_parameter_count
    func family<A, B, C, D, E>(requiresAll componentA: A.Type,
                               _ componentB: B.Type,
                               _ componentC: C.Type,
                               _ componentD: D.Type,
                               _ componentE: E.Type,
                               excludesAll excludedComponents: Component.Type...) -> TypedFamily5<A, B, C, D, E> where A: Component, B: Component, C: Component, D: Component, E: Component {
        return TypedFamily5(self,
                            requiresAll: componentA,
                            componentB,
                            componentC,
                            componentD,
                            componentE,
                            excludesAll: excludedComponents)
    }

}
