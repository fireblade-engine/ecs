//
//  Nexus+Serialization.swift
//
//
//  Created by Christian Treffs on 26.06.20.
//

#if canImport(Foundation)
import struct Foundation.Data

// MARK: - Encoding
extension Nexus: Encodable {
    public func encode(to encoder: Encoder) throws {
        let serialized = try serialize()
        var container = encoder.singleValueContainer()
        try container.encode(serialized)
    }

    final func serialize() throws -> SNexus {
        let version = Version.base

        var componentInstances: [ComponentIdentifier.StableId: SComponent] = [:]
        var entityComponentsMap: [EntityIdentifier: Set<ComponentIdentifier.StableId>] = [:]

        for entitId in self.entityStorage {
            entityComponentsMap[entitId] = []
            let componentIds = self.get(components: entitId) ?? []

            for componentId in componentIds {
                guard let component = self.get(component: componentId, for: entitId) else {
                    fatalError("could not get entity for \(componentId)")
                }
                let componentStableInstanceHash = ComponentIdentifier.makeStableInstanceHash(component: component, entityId: entitId)
                let componentStableTypeHash = ComponentIdentifier.makeStableTypeHash(component: component)
                componentInstances[componentStableInstanceHash] = SComponent(typeId: componentStableTypeHash, instance: component)
                entityComponentsMap[entitId]?.insert(componentStableInstanceHash)
            }
        }

        return SNexus(version: version,
                      entities: entityComponentsMap,
                      components: componentInstances)
    }
}

// MARK: - Decoding
extension Nexus: Decodable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let sNexus = try container.decode(SNexus.self)

        let entityIds = sNexus.entities.map { $0.key }

        self.init(entityStorage: UnorderedSparseSet(),
                  componentsByType: [:],
                  componentsByEntity: [:],
                  entityIdGenerator: EntityIdentifierGenerator(entityIds),
                  familyMembersByTraits: [:],
                  childrenByParentEntity: [:])

        for componentSet in sNexus.entities.values {
            let entity = self.createEntity()
            print(entity.identifier)
            for sCompId in componentSet {
                guard let sComp = sNexus.components[sCompId] else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not find component instance for \(sCompId)."))
                }
                entity.assign(sComp.instance)
            }
        }
    }
}

extension EntityIdentifier: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
extension EntityIdentifier: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(UInt32.self)
        self.init(id)
    }
}

// MARK: - Serialization Model
public struct Version {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
}
extension Version {
    // Base version. Supports entity and component de-/encoding.
    static let base = Version(major: 1, minor: 0, patch: 0)
}
extension Version: Equatable { }
extension Version: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(major).\(minor).\(patch)")
    }
}
extension Version: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let versionString = try container.decode(String.self)
        let components = versionString.components(separatedBy: ".")
        guard components.count == 3 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed version.")
        }

        guard let major = UInt(components[0]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Major invalid.")
        }

        guard let minor = UInt(components[1]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Minor invalid.")
        }

        guard let patch = UInt(components[2]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Patch invalid.")
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

internal struct SNexus {
    let version: Version
    let entities: [EntityIdentifier: Set<ComponentIdentifier.StableId>]
    let components: [ComponentIdentifier.StableId: SComponent]
}
extension SNexus: Encodable { }
extension SNexus: Decodable { }

internal struct SComponent {
    enum Keys: String, CodingKey {
        case typeId
        case instance
    }

    let typeId: ComponentIdentifier.StableId
    let instance: Component

    init(typeId: ComponentIdentifier.StableId, instance: Component) {
        self.typeId = typeId
        self.instance = instance
    }
}
extension SComponent: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(typeId, forKey: .typeId)
        let bytes = withUnsafeBytes(of: instance) {
            Data(bytes: $0.baseAddress!, count: MemoryLayout.stride(ofValue: instance))
        }
        try container.encode(bytes, forKey: .instance)
    }
}
extension SComponent: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.typeId = try container.decode(ComponentIdentifier.StableId.self, forKey: .typeId)
        let instanceData = try container.decode(Data.self, forKey: .instance)
        self.instance = instanceData.withUnsafeBytes {
            $0.baseAddress!.load(as: Component.self)
        }
    }
}

#endif
