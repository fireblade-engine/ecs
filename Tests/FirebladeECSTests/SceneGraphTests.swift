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
        let child1Pos = Position(x: 2, y: 2)
        let nttChild1 = nexus.createEntity(with: child1Pos)

        nttParrent.addChild(nttChild1)

        let family = nexus.family(requires: Position.self)

        var counter: Int = 0

        XCTAssertEqual(child1Pos.x, 2)
        XCTAssertEqual(child1Pos.y, 2)

        family
            .descendRelatives(from: nttParrent)
            .forEach { (parent: Position, child: Position) in
                defer { counter += 1 }

                child.x += parent.x
                child.y += parent.y
        }

        XCTAssertEqual(counter, 1)
        XCTAssertEqual(child1Pos.x, 3)
        XCTAssertEqual(child1Pos.y, 3)
    }

}
