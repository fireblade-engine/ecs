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

extension Requires3: FamilyEncoding where A: Encodable, B: Encodable, C: Encodable {
    public static func encode(components: (A, B, C), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: A.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: B.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: C.self))
    }
}

extension Requires3: FamilyDecoding where A: Decodable, B: Decodable, C: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (A, B, C) {
        let compA = try container.decode(A.self, forKey: strategy.codingKey(for: A.self))
        let compB = try container.decode(B.self, forKey: strategy.codingKey(for: B.self))
        let compC = try container.decode(C.self, forKey: strategy.codingKey(for: C.self))
        return Components(compA, compB, compC)
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
