//
//  Family2.swift
//  
//
//  Created by Christian Treffs on 21.08.19.
//

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
