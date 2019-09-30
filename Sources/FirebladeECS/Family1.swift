//
//  Family1.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public typealias Family1<A: Component> = Family<Requires1<A>>

public struct Requires1<A>: FamilyRequirementsManaging where A: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (A.Type)) {
        componentTypes = [A.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (A) {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        return (compA)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA)
    }
}

extension Nexus {
    public func family<A>(
        requires componentA: A.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family1<A> where A: Component {
        return Family1<A>(nexus: self,
                          requiresAll: componentA,
                          excludesAll: excludedComponents)
    }
}
