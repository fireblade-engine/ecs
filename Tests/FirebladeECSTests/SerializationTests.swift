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
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(nexus)
        
        XCTAssertNotNil(data)
        XCTAssertGreaterThanOrEqual(data.count, 700)
        print(String(data: data, encoding: .utf8)!)
    }
    
    func testFailSerialization() {
        let nexus = Nexus()
        nexus.createEntity(with: Party(partying: true))
        
        let encoder = JSONEncoder()
        XCTAssertThrowsError(try encoder.encode(nexus))
    }
}

extension Nexus: Encodable {
    public func encode(to encoder: Encoder) throws {
        let serialized = try serialize()
        var container = encoder.singleValueContainer()
        try container.encode(serialized)
    }
    
    
    public struct ComponentNotEncodableError: Swift.Error {
        public let localizedDescription: String
        
        init(_ component: Component) {
            localizedDescription = "Component `\(type(of: component))` must conform to `\(Encodable.self)` protocol to be encoded."
        }
    }
}

extension Nexus {
    final func serialize() throws -> SNexus {
        let version = Version(major: 0, minor: 0, patch: 1)
        
        var componentIdMap: [ComponentIdentifier: SComponentTypeId] = [:]
        var componentInstances: [SComponentId: SComponent] = [:]
        var entityComponentsMap: [SEntityId: Set<SComponentId>] = [:]
        
        
        for entitId in self.entityStorage {
            let sEntityId: SEntityId
            sEntityId = SEntityId()
            
            
            entityComponentsMap[sEntityId] = []
            let componentIds = self.get(components: entitId) ?? []
            
            
            for componentId in componentIds {
                
                let sCompTypeId: SComponentTypeId
                if let typeId = componentIdMap[componentId] {
                    sCompTypeId = typeId
                } else {
                    sCompTypeId = SComponentTypeId()
                    componentIdMap[componentId] = sCompTypeId
                }
                
                let component = self.get(component: componentId, for: entitId)!
                let sCompId: SComponentId = SComponentId()
                
                if let encodableComponent = component as? (Component & Encodable) {
                    let sComp = SComponent(typeId: sCompTypeId, instance: encodableComponent)
                    componentInstances[sCompId] = sComp
                    
                    entityComponentsMap[sEntityId]!.insert(sCompId)
                } else {
                    throw ComponentNotEncodableError(component)
                }
            }
        }
        
        return SNexus(version: version,
                      entities: entityComponentsMap,
                      components: componentInstances)
    }
}
public typealias SEntityId = UUID
public typealias SComponentId = UUID
public typealias SComponentTypeId = UUID
public struct Version {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
}
extension Version: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(major).\(minor).\(patch)")
    }
}

public struct SNexus {
    public let version: Version
    public let entities: [SEntityId: Set<SComponentId>]
    public let components: [SComponentId: SComponent]
    
}
extension SNexus:  Encodable { }


public struct SComponent  {
    public let typeId: SComponentTypeId
    public let instance: (Component & Encodable)
    public init(typeId: SComponentTypeId, instance: Component & Encodable) {
        self.typeId = typeId
        self.instance = instance
    }
}
extension SComponent: Encodable {
    public enum Keys: String, CodingKey {
        case typeId
        case instance
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(typeId, forKey: .typeId)
        try instance.encode(to: container.superEncoder(forKey: .instance))
    }
}
