//
//  Nexus+Codable.swift
//
//
//  Created by Christian Treffs on 05.10.19.
//

extension Nexus: Codable {
    public enum CodingKeys: String, CodingKey {
        case version
        case entities
        case freeEntities
        case childrenByParent
        case componentsByType
        case familyMembersByTraits
        case componentIdsByEntity

        public enum Components: String, CodingKey {
            case componentId
            case components
        }

        public enum SparseSet: String, CodingKey {
            case dense
            case sparse

            public enum Entry: String, CodingKey {
                case key
                case element
            }
        }
    }
}
// MARK: - Encodable
extension Nexus {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(Nexus.version, forKey: .version)
        try container.encode(entityStorage, forKey: .entities)
        try container.encode(freeEntities, forKey: .freeEntities)
        try container.encode(childrenByParentEntity, forKey: .childrenByParent)

        try container.encode(familyMembersByTraits, forKey: .familyMembersByTraits)
        try container.encode(componentIdsByEntity, forKey: .componentIdsByEntity)

        // encode componentsByType
        var contComponentsByType = container.nestedUnkeyedContainer(forKey: .componentsByType)
        for (stableId, components) in componentsByType {
            var contComponents = contComponentsByType.nestedContainer(keyedBy: CodingKeys.Components.self)
            try contComponents.encode(stableId, forKey: .componentId)
            var compSparseSet = contComponents.nestedContainer(keyedBy: CodingKeys.SparseSet.self, forKey: .components)
            try compSparseSet.encode(components.sparse, forKey: .sparse)
            var denseContainer = compSparseSet.nestedUnkeyedContainer(forKey: .dense)
            try components.dense.forEach { (entry: UnorderedSparseSet<Component>.Entry) in
                var entryContainer = denseContainer.nestedContainer(keyedBy: CodingKeys.SparseSet.Entry.self)
                try entryContainer.encode(entry.key, forKey: .key)
                try entry.element.encode(to: entryContainer.superEncoder(forKey: .element))
            }
        }
    }
}

// MARK: - Decodable
extension Nexus {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(String.self, forKey: .version)
        if version != Nexus.version {
            throw Error.versionMismatch(required: Nexus.version, provided: version)
        }

        let entityStorage = try container.decode(UnorderedSparseSet<EntityIdentifier>.self, forKey: .entities)
        let freeEntities = try container.decode([EntityIdentifier].self, forKey: .freeEntities)
        let childrenByParentEntity = try container.decode([EntityIdentifier: Set<EntityIdentifier>].self, forKey: .childrenByParent)
        let familyMembersByTraits = try container.decode([FamilyTraitSet: UnorderedSparseSet<EntityIdentifier>].self, forKey: .familyMembersByTraits)
        let componentIdsByEntity = try container.decode([EntityIdentifier: Set<ComponentIdentifier>].self, forKey: .componentIdsByEntity)

        // decode componentsByType
        var contComponentsByType = try container.nestedUnkeyedContainer(forKey: .componentsByType)
        var componentsByType = [ComponentIdentifier: UnorderedSparseSet<Component>]()
        for _ in 0..<(contComponentsByType.count ?? 0) {
            let contComponents = try contComponentsByType.nestedContainer(keyedBy: CodingKeys.Components.self)
            let stableId = try contComponents.decode(ComponentIdentifier.self, forKey: .componentId)

            let compSparseSet = try contComponents.nestedContainer(keyedBy: CodingKeys.SparseSet.self, forKey: .components)
            let sparse = try compSparseSet.decode([Int: Int].self, forKey: .sparse)
            var denseContainer = try compSparseSet.nestedUnkeyedContainer(forKey: .dense)
            var dense = ContiguousArray<UnorderedSparseSet<Component>.Entry>()
            for _ in 0..<(denseContainer.count ?? 0) {
                let entryContainer = try denseContainer.nestedContainer(keyedBy: CodingKeys.SparseSet.Entry.self)
                let key = try entryContainer.decode(UnorderedSparseSet<Component>.Key.self, forKey: .key)
                let element: Component = try Nexus.componentDecoderMap[stableId]!(entryContainer.superDecoder(forKey: .element))
                dense.append(UnorderedSparseSet<Component>.Entry(key: key, element: element))
            }

            componentsByType[stableId] = UnorderedSparseSet<Component>(sparse: sparse, dense: dense)
        }

        self.init(entityStorage: entityStorage,
                  componentsByType: componentsByType,
                  componentsByEntity: componentIdsByEntity,
                  freeEntities: freeEntities,
                  familyMembersByTraits: familyMembersByTraits,
                  childrenByParentEntity: childrenByParentEntity)
    }
}
