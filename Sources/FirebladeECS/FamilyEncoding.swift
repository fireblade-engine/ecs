//
//  FamilyEncoding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 05.08.20.
//

public protocol FamilyEncoding: FamilyRequirementsManaging {
    static func encode(componentsArray: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws
    static func encode(components: Components, into container: inout KeyedEncodingContainer<DynamicCodingKey>, using strategy: CodingStrategy) throws
}

extension FamilyEncoding {
    public static func encode(componentsArray: [Components], into container: inout UnkeyedEncodingContainer, using strategy: CodingStrategy) throws {
        for comps in componentsArray {
            var container = container.nestedContainer(keyedBy: DynamicCodingKey.self)
            try Self.encode(components: comps, into: &container, using: strategy)
        }
    }
}
