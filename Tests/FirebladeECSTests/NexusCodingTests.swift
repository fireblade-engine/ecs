//
//  NexusCodingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 05.10.19.
//

import XCTest
import FirebladeECS

@available(OSX 10.12, *)
class NexusCodingTests: XCTestCase {
    
    lazy var tmpDir: URL = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("NexusCodingTests", isDirectory: true)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    var nexus: Nexus!
    
    override func setUp() {
        super.setUp()
        nexus = Nexus()
        
        let e1 = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "Entity1"))
        let e2 = nexus.createEntity(with: Velocity(a: 2.34), Name(name: "Entity1"))
        let e3 = nexus.createEntity(with: Velocity(a: 5.67), Name(name: "Entity3"))
        e1.addChild(e2)
        e1.addChild(e3)
    }
    
    override func tearDown() {
        super.tearDown()
        nexus = nil
    }
    
    func testEncodeNexusJSON() {
        let file = tmpDir.appendingPathComponent("Nexus.json")
        let encoder = JSONEncoder()
        var data: Data!
        XCTAssertNoThrow(data = try encoder.encode(nexus))
        XCTAssertNoThrow(try data.write(to: file, options: .atomicWrite))
        print(file)
    }
    
    func testDecodeNexusJSON() {
        let file = tmpDir.appendingPathComponent("Nexus.json")
        testEncodeNexusJSON()
        
        let decoder = JSONDecoder()
        var data: Data!
        XCTAssertNoThrow(data = try Data.init(contentsOf: file))
        
        var restoredNexus: Nexus!
        XCTAssertNoThrow(restoredNexus = try decoder.decode(Nexus.self, from: data))
        XCTAssertEqual(restoredNexus, nexus)
        
        let family1 = restoredNexus.family(requires: Name.self)
        let family2 = restoredNexus.family(requires: Position.self)
        let family3 = restoredNexus.family(requires: Velocity.self)
        
        family1.forEach { name in
            print(name.name)
        }
        family2.forEach { pos in
            print(pos.x, pos.y)
        }
        family3.forEach { vel in
            print(vel.a)
        }
        
        
    }
    
}
