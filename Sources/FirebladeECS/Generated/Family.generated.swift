// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable function_parameter_count
// swiftlint:disable large_tuple

// MARK: - Family 1

public typealias Family1<Comp1> = Family<Requires1<Comp1>> where Comp1: Component

public struct Requires1<Comp1>: FamilyRequirementsManaging where Comp1: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type)) {
        componentTypes = [Comp1.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        return (comp1)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1)
    }

    public static func createMember(nexus: Nexus, components: (Comp1)) -> Entity {
        nexus.createEntity(with: components)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (Comp1), child: (Comp1)) {
        let parentcomp1: Comp1 = nexus.get(unsafeComponentFor: parentId)
        let childcomp1: Comp1 = nexus.get(unsafeComponentFor: childId)
        return (parent: (parentcomp1), child: (childcomp1))
    }

}

extension Requires1: FamilyEncoding where Comp1: Encodable {
    public static func encode(components: (Comp1), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components, forKey: strategy.codingKey(for: Comp1.self))
    }
}

extension Requires1: FamilyDecoding where Comp1: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        return comp1
    }
}

extension Nexus {
    public func family<Comp1>(
        requires comp1: Comp1.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family1<Comp1> where Comp1: Component {
        Family1<Comp1>(
            nexus: self,
            requiresAll: (comp1),
            excludesAll: excludedComponents
        )
    }
}


// MARK: - Family 2

public typealias Family2<Comp1, Comp2> = Family<Requires2<Comp1, Comp2>> where Comp1: Component, Comp2: Component

public struct Requires2<Comp1, Comp2>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type)) {
        componentTypes = [Comp1.self, Comp2.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2)) -> Entity {
        nexus.createEntity(with: components.0, components.1)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (Comp1, Comp2), child: (Comp1, Comp2)) {
        let parentcomp1: Comp1 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp2: Comp2 = nexus.get(unsafeComponentFor: parentId)
        let childcomp1: Comp1 = nexus.get(unsafeComponentFor: childId)
        let childcomp2: Comp2 = nexus.get(unsafeComponentFor: childId)
        return (parent: (parentcomp1, parentcomp2), child: (childcomp1, childcomp2))
    }

}

extension Requires2: FamilyEncoding where Comp1: Encodable, Comp2: Encodable {
    public static func encode(components: (Comp1, Comp2), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
    }
}

extension Requires2: FamilyDecoding where Comp1: Decodable, Comp2: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        return Components(comp1, comp2)
    }
}

extension Nexus {
    public func family<Comp1, Comp2>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family2<Comp1, Comp2> where Comp1: Component, Comp2: Component {
        Family2<Comp1, Comp2>(
            nexus: self,
            requiresAll: (comp1, comp2),
            excludesAll: excludedComponents
        )
    }
}


// MARK: - Family 3

public typealias Family3<Comp1, Comp2, Comp3> = Family<Requires3<Comp1, Comp2, Comp3>> where Comp1: Component, Comp2: Component, Comp3: Component

public struct Requires3<Comp1, Comp2, Comp3>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (Comp1, Comp2, Comp3), child: (Comp1, Comp2, Comp3)) {
        let parentcomp1: Comp1 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp2: Comp2 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp3: Comp3 = nexus.get(unsafeComponentFor: parentId)
        let childcomp1: Comp1 = nexus.get(unsafeComponentFor: childId)
        let childcomp2: Comp2 = nexus.get(unsafeComponentFor: childId)
        let childcomp3: Comp3 = nexus.get(unsafeComponentFor: childId)
        return (parent: (parentcomp1, parentcomp2, parentcomp3), child: (childcomp1, childcomp2, childcomp3))
    }

}

extension Requires3: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
    }
}

extension Requires3: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        return Components(comp1, comp2, comp3)
    }
}

extension Nexus {
    public func family<Comp1, Comp2, Comp3>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family3<Comp1, Comp2, Comp3> where Comp1: Component, Comp2: Component, Comp3: Component {
        Family3<Comp1, Comp2, Comp3>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3),
            excludesAll: excludedComponents
        )
    }
}


// MARK: - Family 4

public typealias Family4<Comp1, Comp2, Comp3, Comp4> = Family<Requires4<Comp1, Comp2, Comp3, Comp4>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component

public struct Requires4<Comp1, Comp2, Comp3, Comp4>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3, comp4)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3, comp4)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (Comp1, Comp2, Comp3, Comp4), child: (Comp1, Comp2, Comp3, Comp4)) {
        let parentcomp1: Comp1 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp2: Comp2 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp3: Comp3 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp4: Comp4 = nexus.get(unsafeComponentFor: parentId)
        let childcomp1: Comp1 = nexus.get(unsafeComponentFor: childId)
        let childcomp2: Comp2 = nexus.get(unsafeComponentFor: childId)
        let childcomp3: Comp3 = nexus.get(unsafeComponentFor: childId)
        let childcomp4: Comp4 = nexus.get(unsafeComponentFor: childId)
        return (parent: (parentcomp1, parentcomp2, parentcomp3, parentcomp4), child: (childcomp1, childcomp2, childcomp3, childcomp4))
    }

}

extension Requires4: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
    }
}

extension Requires4: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        return Components(comp1, comp2, comp3, comp4)
    }
}

extension Nexus {
    public func family<Comp1, Comp2, Comp3, Comp4>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family4<Comp1, Comp2, Comp3, Comp4> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component {
        Family4<Comp1, Comp2, Comp3, Comp4>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4),
            excludesAll: excludedComponents
        )
    }
}


// MARK: - Family 5

public typealias Family5<Comp1, Comp2, Comp3, Comp4, Comp5> = Family<Requires5<Comp1, Comp2, Comp3, Comp4, Comp5>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component

public struct Requires5<Comp1, Comp2, Comp3, Comp4, Comp5>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3, comp4, comp5)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4)
    }

    public static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> (parent: (Comp1, Comp2, Comp3, Comp4, Comp5), child: (Comp1, Comp2, Comp3, Comp4, Comp5)) {
        let parentcomp1: Comp1 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp2: Comp2 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp3: Comp3 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp4: Comp4 = nexus.get(unsafeComponentFor: parentId)
        let parentcomp5: Comp5 = nexus.get(unsafeComponentFor: parentId)
        let childcomp1: Comp1 = nexus.get(unsafeComponentFor: childId)
        let childcomp2: Comp2 = nexus.get(unsafeComponentFor: childId)
        let childcomp3: Comp3 = nexus.get(unsafeComponentFor: childId)
        let childcomp4: Comp4 = nexus.get(unsafeComponentFor: childId)
        let childcomp5: Comp5 = nexus.get(unsafeComponentFor: childId)
        return (parent: (parentcomp1, parentcomp2, parentcomp3, parentcomp4, parentcomp5), child: (childcomp1, childcomp2, childcomp3, childcomp4, childcomp5))
    }

}

extension Requires5: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
    }
}

extension Requires5: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        return Components(comp1, comp2, comp3, comp4, comp5)
    }
}

extension Nexus {
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family5<Comp1, Comp2, Comp3, Comp4, Comp5> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component {
        Family5<Comp1, Comp2, Comp3, Comp4, Comp5>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5),
            excludesAll: excludedComponents
        )
    }
}

