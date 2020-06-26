//
//  SerializationTests.swift
//  
//
//  Created by Christian Treffs on 26.06.20.
//

import XCTest
import FirebladeECS

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
