//
//  Family4.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

// swiftlint:disable large_tuple

public typealias Family4<A: Component, B: Component, C: Component, D: Component> = Family<Requires4<A, B, C, D>>

public struct Requires4<A, B, C, D>: FamilyRequirementsManaging where A: Component, B: Component, C: Component, D: Component {
    public let componentTypes: [Component.Type]

    public init(_ types: (A.Type, B.Type, C.Type, D.Type)) {
        componentTypes = [A.self, B.self, C.self, D.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (A, B, C, D) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        let compD: D = nexus.get(unsafeComponentFor: entityId)
        return (compA, compB, compC, compD)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A, B, C, D) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        let compD: D = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA, compB, compC, compD)
    }
}

extension Nexus {
    public func family<A, B, C, D>(
        requiresAll componentA: A.Type,
        _ componentB: B.Type,
        _ componentC: C.Type,
        _ componentD: D.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family4<A, B, C, D> where A: Component, B: Component, C: Component, D: Component {
        return Family4(
            nexus: self,
            requiresAll: (componentA, componentB, componentC, componentD),
            excludesAll: excludedComponents
        )
    }
}
