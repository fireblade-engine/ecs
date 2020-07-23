//
//  FamilyRequirementsManaging.swift
//
//
//  Created by Christian Treffs on 21.08.19.
//

public protocol FamilyRequirementsManaging {
    associatedtype Components
    associatedtype ComponentTypes
    associatedtype EntityAndComponents
    associatedtype RelativesDescending

    init(_ types: ComponentTypes)

    var componentTypes: [Component.Type] { get }

    static func components(nexus: Nexus, entityId: EntityIdentifier) -> Components
    static func entityAndComponents(nexus: Nexus, entityId: EntityIdentifier) -> EntityAndComponents
    static func relativesDescending(nexus: Nexus, parentId: EntityIdentifier, childId: EntityIdentifier) -> RelativesDescending

    static func createMember(nexus: Nexus, components: Components) -> Entity
}

public protocol FamilyEncoding: FamilyRequirementsManaging {
    static func encode(components: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws
    static func encode(components: Components, into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws
}

extension FamilyEncoding {
    public static func encode(components: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws {
        for comps in components {
            var container = container.nestedContainer(keyedBy: DynamicCodingKey.self)
            try Self.encode(components: comps, into: &container, using: strategy)
        }
    }
}

public protocol FamilyDecoding: FamilyRequirementsManaging {
    static func decode(componentsIn unkeyedContainer: inout UnkeyedDecodingContainer, using strategy: CodingStrategy) throws -> [Components]
    static func decode(componentsIn container: KeyedDecodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws -> Components
}

extension FamilyDecoding {
    public static func decode(componentsIn unkeyedContainer: inout UnkeyedDecodingContainer, using strategy: CodingStrategy) throws -> [Components] {
        var components = [Components]()
        if let count = unkeyedContainer.count {
            components.reserveCapacity(count)
        }
        while !unkeyedContainer.isAtEnd {
            let container = try unkeyedContainer.nestedContainer(keyedBy: DynamicCodingKey.self)
            let comps = try Self.decode(componentsIn: container, using: strategy)
            components.append(comps)
        }
        return components
    }
}

public protocol CodingStrategy {
    func codingKey<C>(for componentType: C.Type) -> DynamicCodingKey where C: Component
}

public struct DynamicCodingKey: CodingKey {
    public var intValue: Int?
    public var stringValue: String

    public init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    public init?(stringValue: String) { self.stringValue = stringValue }
}
