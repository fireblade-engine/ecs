//
//  EntityCreationTests.swift
//
//
//  Created by Christian Treffs on 30.07.20.
//

import FirebladeECS
import XCTest

final class EntityCreationTests: XCTestCase {

    func testCreateEntityOneComponent() throws {
        let nexus = Nexus()
        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
        }

        XCTAssertEqual(entity[\Position.x], 1)
        XCTAssertEqual(entity[\Position.y], 2)

        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(nexus.numFamilies, 0)
    }

    func testCreateEntityMultipleComponents() throws {
        let nexus = Nexus()

        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
            Name(name: "Hello")
        }

        XCTAssertEqual(entity[\Position.x], 1)
        XCTAssertEqual(entity[\Position.y], 2)

        XCTAssertEqual(entity[\Name.name], "Hello")

        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 2)
        XCTAssertEqual(nexus.numFamilies, 0)
    }

    func testBulkCreateEntitiesOneComponent() throws {
        let nexus = Nexus()

        let entities = nexus.createEntities(count: 100) { ctx in
            Velocity(a: Float(ctx.index))
        }

        XCTAssertEqual(entities[0][\Velocity.a], 0)
        XCTAssertEqual(entities[99][\Velocity.a], 99)

        XCTAssertEqual(nexus.numEntities, 100)
        XCTAssertEqual(nexus.numComponents, 100)
        XCTAssertEqual(nexus.numFamilies, 0)
    }

    func testBulkCreateEntitiesMultipleComponents() throws {
        let nexus = Nexus()

        let entities = nexus.createEntities(count: 100) { ctx in
            Position(x: ctx.index, y: ctx.index)
            Name(name: "\(ctx.index)")
        }

        XCTAssertEqual(entities[0][\Position.x], 0)
        XCTAssertEqual(entities[0][\Position.y], 0)
        XCTAssertEqual(entities[0][\Name.name], "0")
        XCTAssertEqual(entities[99][\Position.x], 99)
        XCTAssertEqual(entities[99][\Position.y], 99)
        XCTAssertEqual(entities[99][\Name.name], "99")

        XCTAssertEqual(nexus.numEntities, 100)
        XCTAssertEqual(nexus.numComponents, 200)
        XCTAssertEqual(nexus.numFamilies, 0)
    }

}
