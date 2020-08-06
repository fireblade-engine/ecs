// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
// swiftlint:disable function_parameter_count
// swiftlint:disable large_tuple
// swiftlint:disable line_length
// swiftlint:disable multiline_parameters

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
    /// Create a family of entities (aka members) having 1 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 1 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requires: Comp1.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 1 required components each.
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
    /// Create a family of entities (aka members) having 2 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 2 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 2 required components each.
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
    /// Create a family of entities (aka members) having 3 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 3 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 3 required components each.
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
    /// Create a family of entities (aka members) having 4 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 4 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - comp4: Component type 4 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 4 required components each.
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
    /// Create a family of entities (aka members) having 5 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 5 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - comp4: Component type 4 required by members of this family.
    ///   - comp5: Component type 5 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 5 required components each.
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

// MARK: - Family 6

public typealias Family6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6> = Family<Requires6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component

public struct Requires6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5)
    }
}

extension Requires6: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
    }
}

extension Requires6: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 6 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 6 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - comp4: Component type 4 required by members of this family.
    ///   - comp5: Component type 5 required by members of this family.
    ///   - comp6: Component type 6 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 6 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component {
        Family6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 7

public typealias Family7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7> = Family<Requires7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component

public struct Requires7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        let comp7: Comp7 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        let comp7: Comp7 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6)
    }
}

extension Requires7: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
    }
}

extension Requires7: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 7 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 7 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - comp4: Component type 4 required by members of this family.
    ///   - comp5: Component type 5 required by members of this family.
    ///   - comp6: Component type 6 required by members of this family.
    ///   - comp7: Component type 7 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 7 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component {
        Family7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 8

public typealias Family8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8> = Family<Requires8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component

public struct Requires8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        let comp7: Comp7 = nexus.get(unsafeComponentFor: entityId)
        let comp8: Comp8 = nexus.get(unsafeComponentFor: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
        let entity: Entity = nexus.get(unsafeEntity: entityId)
        let comp1: Comp1 = nexus.get(unsafeComponentFor: entityId)
        let comp2: Comp2 = nexus.get(unsafeComponentFor: entityId)
        let comp3: Comp3 = nexus.get(unsafeComponentFor: entityId)
        let comp4: Comp4 = nexus.get(unsafeComponentFor: entityId)
        let comp5: Comp5 = nexus.get(unsafeComponentFor: entityId)
        let comp6: Comp6 = nexus.get(unsafeComponentFor: entityId)
        let comp7: Comp7 = nexus.get(unsafeComponentFor: entityId)
        let comp8: Comp8 = nexus.get(unsafeComponentFor: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7)
    }
}

extension Requires8: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
    }
}

extension Requires8: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 8 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 8 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8) in
    ///   ...
    /// }
    /// ```
    /// **Caveats**
    /// - Component types must be unique per family
    /// - Component type order is arbitrary
    ///
    /// - Parameters:
    ///   - comp1: Component type 1 required by members of this family.
    ///   - comp2: Component type 2 required by members of this family.
    ///   - comp3: Component type 3 required by members of this family.
    ///   - comp4: Component type 4 required by members of this family.
    ///   - comp5: Component type 5 required by members of this family.
    ///   - comp6: Component type 6 required by members of this family.
    ///   - comp7: Component type 7 required by members of this family.
    ///   - comp8: Component type 8 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 8 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component {
        Family8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8),
            excludesAll: excludedComponents
        )
    }
}
