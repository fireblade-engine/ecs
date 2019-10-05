//
//  NexusCodingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 05.10.19.
//

import XCTest
import FirebladeECS

class NexusCodingTests: XCTestCase {

    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()

        let e0 = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "Entity0"))
        let e1 = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "Entity1"))
        let e2 = nexus.createEntity(with: Velocity(a: 2.34), Name(name: "Entity1"))
        nexus.destroy(entity: e0)
        let e3 = nexus.createEntity(with: Velocity(a: 5.67), Name(name: "Entity3"))
        e1.addChild(e2)
        e1.addChild(e3)

        _ = nexus.family(requiresAll: Position.self, Name.self, excludesAll: EmptyComponent.self)
    }

    override func tearDown() {
        super.tearDown()
        nexus = nil
    }

    func testEncodeDecodeNexusJSON() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        var data: Data!
        XCTAssertNoThrow(data = try encoder.encode(nexus))
        XCTAssertGreaterThan(data.count, 0)

        var nexus2: Nexus!
        XCTAssertNoThrow(nexus2 = try decoder.decode(Nexus.self, from: data))
        XCTAssertEqual(nexus2, nexus)

        var data2: Data!
        XCTAssertNoThrow(data2 = try encoder.encode(nexus2))
        XCTAssertGreaterThan(data2.count, 0)
    }
}
