//
//  Family5.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

public typealias Family5<A: Component, B: Component, C: Component, D: Component, E: Component> = Family<Requires5<A, B, C, D, E>>

public struct Requires5<A, B, C, D, E>: FamilyRequirementsManaging where A: Component, B: Component, C: Component, D: Component, E: Component {
    public let componentTypes: [Component.Type]
    public init(_ types: (A.Type, B.Type, C.Type, D.Type, E.Type)) {
        componentTypes = [A.self, B.self, C.self, D.self, E.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (A, B, C, D, E) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        let compD: D = nexus.get(unsafeComponentFor: entityId)
        let compE: E = nexus.get(unsafeComponentFor: entityId)
        return (compA, compB, compC, compD, compE)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A, B, C, D, E) {
        let entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        let compD: D = nexus.get(unsafeComponentFor: entityId)
        let compE: E = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA, compB, compC, compD, compE)
    }
}

extension Nexus {
    // swiftlint:disable function_parameter_count
    public func family<A, B, C, D, E>(
        requiresAll componentA: A.Type,
        _ componentB: B.Type,
        _ componentC: C.Type,
        _ componentD: D.Type,
        _ componentE: E.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family5<A, B, C, D, E> where A: Component, B: Component, C: Component, D: Component, E: Component {
        return Family5(
            nexus: self,
            requiresAll: (componentA, componentB, componentC, componentD, componentE),
            excludesAll: excludedComponents
        )
    }
}
