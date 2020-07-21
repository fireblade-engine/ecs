//
//  Family3.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

// swiftlint:disable large_tuple

public typealias Family3<A: Component, B: Component, C: Component> = Family<Requires3<A, B, C>>

public struct Requires3<A, B, C>: FamilyRequirementsManaging where A: Component, B: Component, C: Component {
    public let componentTypes: [Component.Type]

    public init(_ types: (A.Type, B.Type, C.Type)) {
        componentTypes = [A.self, B.self, C.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (A, B, C) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        return (compA, compB, compC)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A, B, C) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        let compB: B = nexus.get(unsafeComponentFor: entityId)
        let compC: C = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA, compB, compC)
    }
    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) ->
        (parent: (A, B, C), child: (A, B, C)) {
            let pcA: A = nexus.get(unsafeComponentFor: parentId)
            let pcB: B = nexus.get(unsafeComponentFor: parentId)
            let pcC: C = nexus.get(unsafeComponentFor: parentId)
            let ccA: A = nexus.get(unsafeComponentFor: childId)
            let ccB: B = nexus.get(unsafeComponentFor: childId)
            let ccC: C = nexus.get(unsafeComponentFor: childId)
            return (parent: (pcA, pcB, pcC), child: (ccA, ccB, ccC))
    }

    public static func createMember(nexus: Nexus, components: (A, B, C)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2)
    }
}

extension Nexus {
    public func family<A, B, C>(
        requiresAll componentA: A.Type,
        _ componentB: B.Type,
        _ componentC: C.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family3<A, B, C> where A: Component, B: Component, C: Component {
        Family3(
            nexus: self,
            requiresAll: (componentA, componentB, componentC),
            excludesAll: excludedComponents
        )
    }
}
