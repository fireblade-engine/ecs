//
//  Family5.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

// swiftlint:disable large_tuple

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

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) ->
        (parent: (A, B, C, D, E), child: (A, B, C, D, E)) {
            let pcA: A = nexus.get(unsafeComponentFor: parentId)
            let pcB: B = nexus.get(unsafeComponentFor: parentId)
            let pcC: C = nexus.get(unsafeComponentFor: parentId)
            let pcD: D = nexus.get(unsafeComponentFor: parentId)
            let pcE: E = nexus.get(unsafeComponentFor: parentId)
            let ccA: A = nexus.get(unsafeComponentFor: childId)
            let ccB: B = nexus.get(unsafeComponentFor: childId)
            let ccC: C = nexus.get(unsafeComponentFor: childId)
            let ccD: D = nexus.get(unsafeComponentFor: childId)
            let ccE: E = nexus.get(unsafeComponentFor: childId)
            return (parent: (pcA, pcB, pcC, pcD, pcE),
                    child: (ccA, ccB, ccC, ccD, ccE))
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
        Family5(
            nexus: self,
            requiresAll: (componentA, componentB, componentC, componentD, componentE),
            excludesAll: excludedComponents
        )
    }
}
