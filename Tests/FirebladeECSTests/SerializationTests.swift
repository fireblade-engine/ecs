//
//  SerializationTests.swift
//  
//
//  Created by Christian Treffs on 26.06.20.
//

import XCTest
@testable import FirebladeECS

public final class SerializationTests: XCTestCase {
    func testSerialization() throws {
        let nexus = Nexus()
        nexus.createEntity(with: Position(x: 1, y: 4), Name(name: "myName"))
        nexus.createEntity(with: Position(x: 5, y: 18), Name(name: "yourName"))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(nexus)
        
        XCTAssertNotNil(data)
        XCTAssertGreaterThanOrEqual(data.count, 400)
        
        
        let encoder2 = JSONEncoder()
        let data2 = try encoder2.encode(nexus)
        XCTAssertEqual(data.count, data2.count)
        //print(String(data: data, encoding: .utf8)!)
        //print(String(data: data2, encoding: .utf8)!)
    }
    
    func testDeserialization() throws {
        let nexus = Nexus()
        let firstEntity = nexus.createEntity(with: Name(name: "myName"), Position(x: 1, y: 2))
        let secondEntity = nexus.createEntity(with: Velocity(a: 3.14), Party(partying: true))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(nexus)
        
        let decoder = JSONDecoder()
        let nexus2: Nexus = try decoder.decode(Nexus.self, from: data)
        
        
        let firstEntity2 = nexus2.get(entity: firstEntity.identifier)!
        XCTAssertTrue(firstEntity2.has(Name.self))
        XCTAssertTrue(firstEntity2.has(Position.self))
        XCTAssertEqual(firstEntity2.get(component: Name.self)?.name, "myName")
        XCTAssertEqual(firstEntity2.get(component: Position.self)?.x, 1)
        XCTAssertEqual(firstEntity2.get(component: Position.self)?.y, 2)
        
        
        let secondEntity2 = nexus2.get(entity: secondEntity.identifier)!
        XCTAssertTrue(secondEntity2.has(Velocity.self))
        XCTAssertTrue(secondEntity2.has(Party.self))
        XCTAssertEqual(secondEntity2.get(component: Velocity.self)?.a, 3.14)
        XCTAssertEqual(secondEntity2.get(component: Party.self)?.partying, true)
        
        XCTAssertEqual(nexus2.numEntities, nexus.numEntities)
        XCTAssertEqual(nexus2.numComponents, nexus.numComponents)
    }
}

// MARK: - Encoding
extension Nexus: Encodable {
    public func encode(to encoder: Encoder) throws {
        let serialized = try serialize()
        var container = encoder.singleValueContainer()
        try container.encode(serialized)
    }
    
    final func serialize() throws -> SNexus {
        let version = Version(major: 0, minor: 0, patch: 1)
        
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
                entityComponentsMap[entitId]!.insert(componentStableInstanceHash)
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

// MARK: - Model
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


public struct Version {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
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

public struct SNexus {
    public let version: Version
    public let entities: [EntityIdentifier: Set<ComponentIdentifier.StableId>]
    public let components: [ComponentIdentifier.StableId: SComponent]
    
}
extension SNexus: Encodable { }
extension SNexus: Decodable { }

public struct SComponent  {
    public enum Keys: String, CodingKey {
        case typeId
        case instance
    }
    
    public let typeId: ComponentIdentifier.StableId
    public let instance: Component
    public init(typeId: ComponentIdentifier.StableId, instance: Component) {
        self.typeId = typeId
        self.instance = instance
    }
}
extension SComponent: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(typeId, forKey: .typeId)
        let bytes = withUnsafeBytes(of: instance) { Data(bytes: $0.baseAddress!, count: MemoryLayout.stride(ofValue: instance)) }
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
