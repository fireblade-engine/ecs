//
//  Nexus+Serialization.swift
//
//
//  Created by Christian Treffs on 26.06.20.
//

#if canImport(Foundation)
    import struct Foundation.Data

    extension Nexus {
        final func serialize() throws -> SNexus {
            var componentInstances: [ComponentIdentifier.StableId: SComponent<SNexus>] = [:]
            var entityComponentsMap: [EntityIdentifier: Set<ComponentIdentifier.StableId>] = [:]

            for entitId in componentIdsByEntity.keys {
                entityComponentsMap[entitId] = []
                let componentIds = self.get(components: entitId) ?? []

                for componentId in componentIds {
                    let component = self.get(unsafe: componentId, for: entitId)
                    let componentStableInstanceHash = ComponentIdentifier.makeStableInstanceHash(component: component, entityId: entitId)
                    componentInstances[componentStableInstanceHash] = SComponent.component(component)
                    entityComponentsMap[entitId]?.insert(componentStableInstanceHash)
                }
            }

            return SNexus(version: version,
                          entities: entityComponentsMap,
                          components: componentInstances)
        }

        final func deserialize(from sNexus: SNexus, into nexus: Nexus) throws {
            for freeId in sNexus.entities.map(\.key).reversed() {
                nexus.entityIdGenerator.markUnused(entityId: freeId)
            }

            for componentSet in sNexus.entities.values {
                let entity = createEntity()
                for sCompId in componentSet {
                    guard let sComp = sNexus.components[sCompId] else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Could not find component instance for \(sCompId)."))
                    }

                    switch sComp {
                    case let .component(comp):
                        entity.assign(comp)
                    }
                }
            }
        }
    }

    struct SNexus {
        let version: Version
        let entities: [EntityIdentifier: Set<ComponentIdentifier.StableId>]
        let components: [ComponentIdentifier.StableId: SComponent<SNexus>]
    }

    extension SNexus: Encodable {}
    extension SNexus: Decodable {}

    protocol ComponentEncoding {
        static func encode(component: Component, to encoder: Encoder) throws
    }

    protocol ComponentDecoding {
        static func decode(from decoder: Decoder) throws -> Component
    }

    typealias ComponentCodable = ComponentDecoding & ComponentEncoding

    extension SNexus: ComponentEncoding {
        static func encode(component: Component, to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            // Use an explicitly typed pointer so Swift 6 does not implicitly open the existential to its concrete class reference.
            let pointer = UnsafeMutablePointer<any Component>.allocate(capacity: 1)
            pointer.initialize(to: component)
            defer { pointer.deinitialize(count: 1); pointer.deallocate() }
            let bytes = Data(bytes: pointer, count: MemoryLayout<any Component>.stride)
            try container.encode(bytes)
        }
    }

    extension SNexus: ComponentDecoding {
        static func decode(from decoder: Decoder) throws -> Component {
            let container = try decoder.singleValueContainer()
            let instanceData = try container.decode(Data.self)
            return instanceData.withUnsafeBytes {
                $0.baseAddress!.load(as: Component.self)
            }
        }
    }

    enum SComponent<CodingStrategy: ComponentCodable> {
        case component(Component)
    }

    extension SComponent: Encodable {
        public func encode(to encoder: Encoder) throws {
            switch self {
            case let .component(comp):
                try CodingStrategy.encode(component: comp, to: encoder)
            }
        }
    }

    extension SComponent: Decodable {
        public init(from decoder: Decoder) throws {
            self = try .component(CodingStrategy.decode(from: decoder))
        }
    }

#endif
