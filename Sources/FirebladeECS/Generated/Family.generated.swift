// Generated using Sourcery 1.6.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable file_length
// swiftlint:disable function_parameter_count
// swiftlint:disable large_tuple
// swiftlint:disable line_length
// swiftlint:disable multiline_parameters

// MARK: - Family 1

public typealias Family1<Comp1> = Family<Requires1<Comp1>> where Comp1: Component

public protocol RequiringComponents1: FamilyRequirementsManaging where Components == (Comp1) {
    associatedtype Comp1: Component
}

public struct Requires1<Comp1>: FamilyRequirementsManaging where Comp1: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type)) {
        componentTypes = [Comp1.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        return (comp1)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        return (entity, comp1)
    }

    public static func createMember(nexus: Nexus, components: (Comp1)) -> Entity {
        nexus.createEntity(with: components)
    }
}

extension Requires1: RequiringComponents1 { }

extension FamilyMemberBuilder where R: RequiringComponents1  {
    public static func buildBlock(_ comp1: R.Comp1) -> (R.Components) {
        return (comp1)
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

public protocol RequiringComponents2: FamilyRequirementsManaging where Components == (Comp1, Comp2) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
}

public struct Requires2<Comp1, Comp2>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type)) {
        componentTypes = [Comp1.self, Comp2.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        return (comp1, comp2)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2)) -> Entity {
        nexus.createEntity(with: components.0, components.1)
    }
}

extension Requires2: RequiringComponents2 { }

extension FamilyMemberBuilder where R: RequiringComponents2  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2) -> (R.Components) {
        return (comp1, comp2)
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

public protocol RequiringComponents3: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
}

public struct Requires3<Comp1, Comp2, Comp3>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2)
    }
}

extension Requires3: RequiringComponents3 { }

extension FamilyMemberBuilder where R: RequiringComponents3  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3) -> (R.Components) {
        return (comp1, comp2, comp3)
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

public protocol RequiringComponents4: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
}

public struct Requires4<Comp1, Comp2, Comp3, Comp4>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3)
    }
}

extension Requires4: RequiringComponents4 { }

extension FamilyMemberBuilder where R: RequiringComponents4  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4) -> (R.Components) {
        return (comp1, comp2, comp3, comp4)
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

public protocol RequiringComponents5: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
}

public struct Requires5<Comp1, Comp2, Comp3, Comp4, Comp5>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4)
    }
}

extension Requires5: RequiringComponents5 { }

extension FamilyMemberBuilder where R: RequiringComponents5  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5)
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

public protocol RequiringComponents6: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
}

public struct Requires6<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5)
    }
}

extension Requires6: RequiringComponents6 { }

extension FamilyMemberBuilder where R: RequiringComponents6  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6)
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

public protocol RequiringComponents7: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
}

public struct Requires7<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6)
    }
}

extension Requires7: RequiringComponents7 { }

extension FamilyMemberBuilder where R: RequiringComponents7  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7)
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

public protocol RequiringComponents8: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
}

public struct Requires8<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7)
    }
}

extension Requires8: RequiringComponents8 { }

extension FamilyMemberBuilder where R: RequiringComponents8  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8)
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

// MARK: - Family 9

public typealias Family9<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9> = Family<Requires9<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component

public protocol RequiringComponents9: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
}

public struct Requires9<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8)
    }
}

extension Requires9: RequiringComponents9 { }

extension FamilyMemberBuilder where R: RequiringComponents9  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9)
    }
}

extension Requires9: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
    }
}

extension Requires9: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 9 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 9 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 9 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family9<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component {
        Family9<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 10

public typealias Family10<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10> = Family<Requires10<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component

public protocol RequiringComponents10: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
}

public struct Requires10<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9)
    }
}

extension Requires10: RequiringComponents10 { }

extension FamilyMemberBuilder where R: RequiringComponents10  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10)
    }
}

extension Requires10: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
    }
}

extension Requires10: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 10 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 10 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 10 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family10<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component {
        Family10<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 11

public typealias Family11<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11> = Family<Requires11<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component

public protocol RequiringComponents11: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
}

public struct Requires11<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10)
    }
}

extension Requires11: RequiringComponents11 { }

extension FamilyMemberBuilder where R: RequiringComponents11  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11)
    }
}

extension Requires11: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
    }
}

extension Requires11: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 11 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 11 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 11 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family11<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component {
        Family11<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 12

public typealias Family12<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12> = Family<Requires12<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component

public protocol RequiringComponents12: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
    associatedtype Comp12: Component
}

public struct Requires12<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type, Comp12.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10, components.11)
    }
}

extension Requires12: RequiringComponents12 { }

extension FamilyMemberBuilder where R: RequiringComponents12  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11, _ comp12: R.Comp12) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12)
    }
}

extension Requires12: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable, Comp12: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
        try container.encode(components.11, forKey: strategy.codingKey(for: Comp12.self))
    }
}

extension Requires12: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable, Comp12: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        let comp12 = try container.decode(Comp12.self, forKey: strategy.codingKey(for: Comp12.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 12 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 12 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - comp12: Component type 12 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 12 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type, _ comp12: Comp12.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family12<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component {
        Family12<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 13

public typealias Family13<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13> = Family<Requires13<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component

public protocol RequiringComponents13: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
    associatedtype Comp12: Component
    associatedtype Comp13: Component
}

public struct Requires13<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type, Comp12.Type, Comp13.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10, components.11, components.12)
    }
}

extension Requires13: RequiringComponents13 { }

extension FamilyMemberBuilder where R: RequiringComponents13  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11, _ comp12: R.Comp12, _ comp13: R.Comp13) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13)
    }
}

extension Requires13: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable, Comp12: Encodable, Comp13: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
        try container.encode(components.11, forKey: strategy.codingKey(for: Comp12.self))
        try container.encode(components.12, forKey: strategy.codingKey(for: Comp13.self))
    }
}

extension Requires13: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable, Comp12: Decodable, Comp13: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        let comp12 = try container.decode(Comp12.self, forKey: strategy.codingKey(for: Comp12.self))
        let comp13 = try container.decode(Comp13.self, forKey: strategy.codingKey(for: Comp13.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 13 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 13 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - comp12: Component type 12 required by members of this family.
    ///   - comp13: Component type 13 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 13 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type, _ comp12: Comp12.Type, _ comp13: Comp13.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family13<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component {
        Family13<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 14

public typealias Family14<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14> = Family<Requires14<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component

public protocol RequiringComponents14: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
    associatedtype Comp12: Component
    associatedtype Comp13: Component
    associatedtype Comp14: Component
}

public struct Requires14<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type, Comp12.Type, Comp13.Type, Comp14.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10, components.11, components.12, components.13)
    }
}

extension Requires14: RequiringComponents14 { }

extension FamilyMemberBuilder where R: RequiringComponents14  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11, _ comp12: R.Comp12, _ comp13: R.Comp13, _ comp14: R.Comp14) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14)
    }
}

extension Requires14: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable, Comp12: Encodable, Comp13: Encodable, Comp14: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
        try container.encode(components.11, forKey: strategy.codingKey(for: Comp12.self))
        try container.encode(components.12, forKey: strategy.codingKey(for: Comp13.self))
        try container.encode(components.13, forKey: strategy.codingKey(for: Comp14.self))
    }
}

extension Requires14: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable, Comp12: Decodable, Comp13: Decodable, Comp14: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        let comp12 = try container.decode(Comp12.self, forKey: strategy.codingKey(for: Comp12.self))
        let comp13 = try container.decode(Comp13.self, forKey: strategy.codingKey(for: Comp13.self))
        let comp14 = try container.decode(Comp14.self, forKey: strategy.codingKey(for: Comp14.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 14 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 14 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - comp12: Component type 12 required by members of this family.
    ///   - comp13: Component type 13 required by members of this family.
    ///   - comp14: Component type 14 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 14 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type, _ comp12: Comp12.Type, _ comp13: Comp13.Type, _ comp14: Comp14.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family14<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component {
        Family14<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 15

public typealias Family15<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15> = Family<Requires15<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component

public protocol RequiringComponents15: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
    associatedtype Comp12: Component
    associatedtype Comp13: Component
    associatedtype Comp14: Component
    associatedtype Comp15: Component
}

public struct Requires15<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type, Comp12.Type, Comp13.Type, Comp14.Type, Comp15.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self, Comp15.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        let comp15: Comp15 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        let comp15: Comp15 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10, components.11, components.12, components.13, components.14)
    }
}

extension Requires15: RequiringComponents15 { }

extension FamilyMemberBuilder where R: RequiringComponents15  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11, _ comp12: R.Comp12, _ comp13: R.Comp13, _ comp14: R.Comp14, _ comp15: R.Comp15) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15)
    }
}

extension Requires15: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable, Comp12: Encodable, Comp13: Encodable, Comp14: Encodable, Comp15: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
        try container.encode(components.11, forKey: strategy.codingKey(for: Comp12.self))
        try container.encode(components.12, forKey: strategy.codingKey(for: Comp13.self))
        try container.encode(components.13, forKey: strategy.codingKey(for: Comp14.self))
        try container.encode(components.14, forKey: strategy.codingKey(for: Comp15.self))
    }
}

extension Requires15: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable, Comp12: Decodable, Comp13: Decodable, Comp14: Decodable, Comp15: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        let comp12 = try container.decode(Comp12.self, forKey: strategy.codingKey(for: Comp12.self))
        let comp13 = try container.decode(Comp13.self, forKey: strategy.codingKey(for: Comp13.self))
        let comp14 = try container.decode(Comp14.self, forKey: strategy.codingKey(for: Comp14.self))
        let comp15 = try container.decode(Comp15.self, forKey: strategy.codingKey(for: Comp15.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 15 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 15 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self, Comp15.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - comp12: Component type 12 required by members of this family.
    ///   - comp13: Component type 13 required by members of this family.
    ///   - comp14: Component type 14 required by members of this family.
    ///   - comp15: Component type 15 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 15 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type, _ comp12: Comp12.Type, _ comp13: Comp13.Type, _ comp14: Comp14.Type, _ comp15: Comp15.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family15<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component {
        Family15<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15),
            excludesAll: excludedComponents
        )
    }
}

// MARK: - Family 16

public typealias Family16<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16> = Family<Requires16<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16>> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component, Comp16: Component

public protocol RequiringComponents16: FamilyRequirementsManaging where Components == (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16) {
    associatedtype Comp1: Component
    associatedtype Comp2: Component
    associatedtype Comp3: Component
    associatedtype Comp4: Component
    associatedtype Comp5: Component
    associatedtype Comp6: Component
    associatedtype Comp7: Component
    associatedtype Comp8: Component
    associatedtype Comp9: Component
    associatedtype Comp10: Component
    associatedtype Comp11: Component
    associatedtype Comp12: Component
    associatedtype Comp13: Component
    associatedtype Comp14: Component
    associatedtype Comp15: Component
    associatedtype Comp16: Component
}

public struct Requires16<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16>: FamilyRequirementsManaging where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component, Comp16: Component {
    public let componentTypes: [Component.Type]

    public init(_ components: (Comp1.Type, Comp2.Type, Comp3.Type, Comp4.Type, Comp5.Type, Comp6.Type, Comp7.Type, Comp8.Type, Comp9.Type, Comp10.Type, Comp11.Type, Comp12.Type, Comp13.Type, Comp14.Type, Comp15.Type, Comp16.Type)) {
        componentTypes = [Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self, Comp15.self, Comp16.self]
    }

    public static func components(nexus: Nexus, entityId: EntityIdentifier) -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16) {
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        let comp15: Comp15 = nexus.get(unsafe: entityId)
        let comp16: Comp16 = nexus.get(unsafe: entityId)
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16)
    }

    public static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> (Entity, Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16) {
        let entity: Entity = Entity(nexus: nexus, id: entityId)
        let comp1: Comp1 = nexus.get(unsafe: entityId)
        let comp2: Comp2 = nexus.get(unsafe: entityId)
        let comp3: Comp3 = nexus.get(unsafe: entityId)
        let comp4: Comp4 = nexus.get(unsafe: entityId)
        let comp5: Comp5 = nexus.get(unsafe: entityId)
        let comp6: Comp6 = nexus.get(unsafe: entityId)
        let comp7: Comp7 = nexus.get(unsafe: entityId)
        let comp8: Comp8 = nexus.get(unsafe: entityId)
        let comp9: Comp9 = nexus.get(unsafe: entityId)
        let comp10: Comp10 = nexus.get(unsafe: entityId)
        let comp11: Comp11 = nexus.get(unsafe: entityId)
        let comp12: Comp12 = nexus.get(unsafe: entityId)
        let comp13: Comp13 = nexus.get(unsafe: entityId)
        let comp14: Comp14 = nexus.get(unsafe: entityId)
        let comp15: Comp15 = nexus.get(unsafe: entityId)
        let comp16: Comp16 = nexus.get(unsafe: entityId)
        return (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16)
    }

    public static func createMember(nexus: Nexus, components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16)) -> Entity {
        nexus.createEntity(with: components.0, components.1, components.2, components.3, components.4, components.5, components.6, components.7, components.8, components.9, components.10, components.11, components.12, components.13, components.14, components.15)
    }
}

extension Requires16: RequiringComponents16 { }

extension FamilyMemberBuilder where R: RequiringComponents16  {
    public static func buildBlock(_ comp1: R.Comp1, _ comp2: R.Comp2, _ comp3: R.Comp3, _ comp4: R.Comp4, _ comp5: R.Comp5, _ comp6: R.Comp6, _ comp7: R.Comp7, _ comp8: R.Comp8, _ comp9: R.Comp9, _ comp10: R.Comp10, _ comp11: R.Comp11, _ comp12: R.Comp12, _ comp13: R.Comp13, _ comp14: R.Comp14, _ comp15: R.Comp15, _ comp16: R.Comp16) -> (R.Components) {
        return (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16)
    }
}

extension Requires16: FamilyEncoding where Comp1: Encodable, Comp2: Encodable, Comp3: Encodable, Comp4: Encodable, Comp5: Encodable, Comp6: Encodable, Comp7: Encodable, Comp8: Encodable, Comp9: Encodable, Comp10: Encodable, Comp11: Encodable, Comp12: Encodable, Comp13: Encodable, Comp14: Encodable, Comp15: Encodable, Comp16: Encodable {
    public static func encode(components: (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16), into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws {
        try container.encode(components.0, forKey: strategy.codingKey(for: Comp1.self))
        try container.encode(components.1, forKey: strategy.codingKey(for: Comp2.self))
        try container.encode(components.2, forKey: strategy.codingKey(for: Comp3.self))
        try container.encode(components.3, forKey: strategy.codingKey(for: Comp4.self))
        try container.encode(components.4, forKey: strategy.codingKey(for: Comp5.self))
        try container.encode(components.5, forKey: strategy.codingKey(for: Comp6.self))
        try container.encode(components.6, forKey: strategy.codingKey(for: Comp7.self))
        try container.encode(components.7, forKey: strategy.codingKey(for: Comp8.self))
        try container.encode(components.8, forKey: strategy.codingKey(for: Comp9.self))
        try container.encode(components.9, forKey: strategy.codingKey(for: Comp10.self))
        try container.encode(components.10, forKey: strategy.codingKey(for: Comp11.self))
        try container.encode(components.11, forKey: strategy.codingKey(for: Comp12.self))
        try container.encode(components.12, forKey: strategy.codingKey(for: Comp13.self))
        try container.encode(components.13, forKey: strategy.codingKey(for: Comp14.self))
        try container.encode(components.14, forKey: strategy.codingKey(for: Comp15.self))
        try container.encode(components.15, forKey: strategy.codingKey(for: Comp16.self))
    }
}

extension Requires16: FamilyDecoding where Comp1: Decodable, Comp2: Decodable, Comp3: Decodable, Comp4: Decodable, Comp5: Decodable, Comp6: Decodable, Comp7: Decodable, Comp8: Decodable, Comp9: Decodable, Comp10: Decodable, Comp11: Decodable, Comp12: Decodable, Comp13: Decodable, Comp14: Decodable, Comp15: Decodable, Comp16: Decodable {
    public static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> (Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16) {
        let comp1 = try container.decode(Comp1.self, forKey: strategy.codingKey(for: Comp1.self))
        let comp2 = try container.decode(Comp2.self, forKey: strategy.codingKey(for: Comp2.self))
        let comp3 = try container.decode(Comp3.self, forKey: strategy.codingKey(for: Comp3.self))
        let comp4 = try container.decode(Comp4.self, forKey: strategy.codingKey(for: Comp4.self))
        let comp5 = try container.decode(Comp5.self, forKey: strategy.codingKey(for: Comp5.self))
        let comp6 = try container.decode(Comp6.self, forKey: strategy.codingKey(for: Comp6.self))
        let comp7 = try container.decode(Comp7.self, forKey: strategy.codingKey(for: Comp7.self))
        let comp8 = try container.decode(Comp8.self, forKey: strategy.codingKey(for: Comp8.self))
        let comp9 = try container.decode(Comp9.self, forKey: strategy.codingKey(for: Comp9.self))
        let comp10 = try container.decode(Comp10.self, forKey: strategy.codingKey(for: Comp10.self))
        let comp11 = try container.decode(Comp11.self, forKey: strategy.codingKey(for: Comp11.self))
        let comp12 = try container.decode(Comp12.self, forKey: strategy.codingKey(for: Comp12.self))
        let comp13 = try container.decode(Comp13.self, forKey: strategy.codingKey(for: Comp13.self))
        let comp14 = try container.decode(Comp14.self, forKey: strategy.codingKey(for: Comp14.self))
        let comp15 = try container.decode(Comp15.self, forKey: strategy.codingKey(for: Comp15.self))
        let comp16 = try container.decode(Comp16.self, forKey: strategy.codingKey(for: Comp16.self))
        return Components(comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16)
    }
}

extension Nexus {
    /// Create a family of entities (aka members) having 16 required components.
    ///
    /// A family is a collection of entities with uniform component types per entity.
    /// Entities that are be part of this family will have at least the 16 required components,
    /// but may have more components assigned.
    ///
    /// A family is just a view on (component) data, creating them is cheap.
    /// Use them to iterate efficiently over entities with the same components assigned.
    /// Families with the same requirements provide a view on the same collection of entities (aka members).
    /// A family conforms to the `LazySequenceProtocol` and therefore can be accessed like any other (lazy) sequence.
    ///
    /// **General usage**
    /// ```swift
    /// let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self, Comp9.self, Comp10.self, Comp11.self, Comp12.self, Comp13.self, Comp14.self, Comp15.self, Comp16.self)
    /// // iterate each entity's components
    /// family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16) in
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
    ///   - comp9: Component type 9 required by members of this family.
    ///   - comp10: Component type 10 required by members of this family.
    ///   - comp11: Component type 11 required by members of this family.
    ///   - comp12: Component type 12 required by members of this family.
    ///   - comp13: Component type 13 required by members of this family.
    ///   - comp14: Component type 14 required by members of this family.
    ///   - comp15: Component type 15 required by members of this family.
    ///   - comp16: Component type 16 required by members of this family.
    ///   - excludedComponents: All component types that must not be assigned to an entity in this family.
    /// - Returns: The family of entities having 16 required components each.
    public func family<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16>(
        requiresAll comp1: Comp1.Type, _ comp2: Comp2.Type, _ comp3: Comp3.Type, _ comp4: Comp4.Type, _ comp5: Comp5.Type, _ comp6: Comp6.Type, _ comp7: Comp7.Type, _ comp8: Comp8.Type, _ comp9: Comp9.Type, _ comp10: Comp10.Type, _ comp11: Comp11.Type, _ comp12: Comp12.Type, _ comp13: Comp13.Type, _ comp14: Comp14.Type, _ comp15: Comp15.Type, _ comp16: Comp16.Type,
        excludesAll excludedComponents: Component.Type...
    ) -> Family16<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16> where Comp1: Component, Comp2: Component, Comp3: Component, Comp4: Component, Comp5: Component, Comp6: Component, Comp7: Component, Comp8: Component, Comp9: Component, Comp10: Component, Comp11: Component, Comp12: Component, Comp13: Component, Comp14: Component, Comp15: Component, Comp16: Component {
        Family16<Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9, Comp10, Comp11, Comp12, Comp13, Comp14, Comp15, Comp16>(
            nexus: self,
            requiresAll: (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8, comp9, comp10, comp11, comp12, comp13, comp14, comp15, comp16),
            excludesAll: excludedComponents
        )
    }
}
