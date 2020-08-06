//
//  FamilyDecoding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

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
