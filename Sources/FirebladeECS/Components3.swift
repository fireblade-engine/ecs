//
//  Components3.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

public typealias Family3<A: Component, B: Component, C: Component> = Family<Components3<A, B, C>>

public struct Components3<A, B, C>: ComponentsProviding where A: Component, B: Component, C: Component {
    public let componentTypes: [Component.Type]
    public init(_ types: (A.Type, B.Type, C.Type)) {
        componentTypes = [A.self, B.self, C.self]
    }

    public static func getComponents(nexus: Nexus, entityId: EntityIdentifier) -> (A, B, C) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        return (compA, compB, compC)
    }
}

extension Nexus {
    public func family<A, B, C>(
        requiresAll componentA: A.Type,
        _ componentB: B.Type,
        _ componentC: C.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family3<A, B, C> where A: Component, B: Component, C: Component {
        return Family3(
            nexus: self,
            requiresAll: (componentA, componentB, componentC),
            excludesAll: excludedComponents
        )
    }
}
