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

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) ->
        (parent: (A, B, C, D), child: (A, B, C, D)) {
            let pcA: A = nexus.get(unsafeComponentFor: parentId)
            let pcB: B = nexus.get(unsafeComponentFor: parentId)
            let pcC: C = nexus.get(unsafeComponentFor: parentId)
            let pcD: D = nexus.get(unsafeComponentFor: parentId)
            let ccA: A = nexus.get(unsafeComponentFor: childId)
            let ccB: B = nexus.get(unsafeComponentFor: childId)
            let ccC: C = nexus.get(unsafeComponentFor: childId)
            let ccD: D = nexus.get(unsafeComponentFor: childId)
            return (parent: (pcA, pcB, pcC, pcD), child: (ccA, ccB, ccC, ccD))
    }

    public static func createMember(nexus: Nexus, components: (A, B, C, D)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3)
    }
}

extension Requires4: FamilyEncoding where A: Encodable, B: Encodable, C: Encodable, D: Encodable {
    public static func encode(components: (A, B, C, D), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: A.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: B.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: C.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: D.self))
    }
}

extension Requires4: FamilyDecoding where A: Decodable, B: Decodable, C: Decodable, D: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (A, B, C, D) {
        let compA = try container.decode(A.self, forKey: strategy.codingKey(for: A.self))
        let compB = try container.decode(B.self, forKey: strategy.codingKey(for: B.self))
        let compC = try container.decode(C.self, forKey: strategy.codingKey(for: C.self))
        let compD = try container.decode(D.self, forKey: strategy.codingKey(for: D.self))
        return Components(compA, compB, compC, compD)
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
        Family4(
            nexus: self,
            requiresAll: (componentA, componentB, componentC, componentD),
            excludesAll: excludedComponents
        )
    }
}
