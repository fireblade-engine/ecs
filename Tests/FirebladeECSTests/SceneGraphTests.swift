//
//  SceneGraphTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 30.09.19.
//

import XCTest
import FirebladeECS

class SceneGraphTests: XCTestCase {

    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    override func tearDown() {
        super.tearDown()
        nexus = nil
    }

    func testAddChild() {
        let nttParrent = nexus.createEntity()
        let nttChild1 = nexus.createEntity()
        XCTAssertEqual(nttParrent.numChildren, 0)
        XCTAssertTrue(nttParrent.addChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 1)
        XCTAssertFalse(nttParrent.addChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 1)
    }

    func testRemoveChild() {
        let nttParrent = nexus.createEntity()
        let nttChild1 = nexus.createEntity()

        XCTAssertEqual(nttParrent.numChildren, 0)
        XCTAssertTrue(nttParrent.addChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 1)
        XCTAssertTrue(nttParrent.removeChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 0)
        XCTAssertFalse(nttParrent.removeChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 0)
        XCTAssertTrue(nttParrent.addChild(nttChild1))
        XCTAssertEqual(nttParrent.numChildren, 1)
    }

    func testRemoveAllChildren() {
        let nttParrent = nexus.createEntity()
        let nttChild1 = nexus.createEntity()
        let nttChild2 = nexus.createEntity()

        XCTAssertEqual(nttParrent.numChildren, 0)
        nttParrent.addChild(nttChild1)
        nttParrent.addChild(nttChild2)
        XCTAssertEqual(nttParrent.numChildren, 2)

        nttParrent.removeAllChildren()
        XCTAssertEqual(nttParrent.numChildren, 0)
    }

    func testDescendRelatives() {
        let nttParrent = nexus.createEntity(with: Position(x: 1, y: 1))
        let nttChild1 = nexus.createEntity(with: Position(x: 2, y: 2))

        nttParrent.addChild(nttChild1)

        let family = nexus.family(requires: Position.self)

        family
            .descendRelatives.forEach { (_: Position, _: Position) in
                // TODO:
        }
    }

}
