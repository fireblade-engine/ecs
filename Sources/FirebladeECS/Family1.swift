//
//  Family1.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public typealias Family1<A: Component> = Family<Requires1<A>>

public struct Requires1<A>: FamilyRequirementsManaging where A: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: A.Type) {
        componentTypes = [A.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> A {
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        return (compA)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, A) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let compA: A = nexus.get(unsafeComponentFor: entityId)
        return (entity, compA)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: A, child: A) {
        let parentCompA: A = nexus.get(unsafeComponentFor: parentId)
        let childCompA: A = nexus.get(unsafeComponentFor: childId)
        return (parent: parentCompA, child: childCompA)
    }

    public static func createMember(nexus: Nexus, components: A) -> Entity {
        nexus.createEntity(with: components)
    }
}

extension Requires1: FamilyDecoding where A: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> A {
        try container.decode(A.self, forKey: strategy.codingKey(for: A.self))
    }
}

extension Requires1: FamilyEncoding where A: Encodable {
    public static func encode(components: Components, into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components, forKey: strategy.codingKey(for: A.self))
    }
}

extension Nexus {
    public func family<A>(
        requires componentA: A.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family1<A> where A: Component {
        Family1<A>(nexus: self,
                   requiresAll: componentA,
                   excludesAll: excludedComponents)
    }
}
