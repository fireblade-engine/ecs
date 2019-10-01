//
//  Family2.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

// swiftlint:disable large_tuple

public typealias Family2<A: Component, B: Component> = Family<Requires2<A, B>>

public struct Requires2<A, B>: FamilyRequirementsManaging where A: Component, B: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (A.Type, B.Type)) {
        componentTypes = [ A.self, B.self]
    }
    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (A, B) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        return (compA, compB)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A, B) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA, compB)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (A, B), child: (A, B)) {
        let pcA: A = nexus.get(unsafeComponentFor: parentId)
        let pcB: B = nexus.get(unsafeComponentFor: parentId)
        let ccA: A = nexus.get(unsafeComponentFor: childId)
        let ccB: B = nexus.get(unsafeComponentFor: childId)
        return (parent: (pcA, pcB), child: (ccA, ccB))
    }
}

extension Nexus {
    public func family<A, B>(
        requiresAll componentA: A.Type,
        _ componentB: B.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family2<A, B> where A: Component, B: Component {
        return Family2<A, B>(
            nexus: self,
            requiresAll: (componentA, componentB),
            excludesAll: excludedComponents
        )
    }
}
