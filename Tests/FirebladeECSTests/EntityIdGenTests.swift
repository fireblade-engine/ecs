//
//  EntityIdGenTests.swift
//
//
//  Created by Christian Treffs on 21.08.20.
//

import FirebladeECS
import XCTest

final class EntityIdGenTests: XCTestCase {
    var gen: EntityIdentifierGenerator!

    override func setUp() {
        super.setUp()
        gen = DefaultEntityIdGenerator()
    }

    func testGeneratorDefaultInit() {
        XCTAssertEqual(gen.nextId(), 0)
    }

    func testLinearIncrement() {
        for i in 0..<1_000_000 {
            XCTAssertEqual(gen.nextId(), EntityIdentifier(EntityIdentifier.Identifier(i)))
        }
    }

    func testGenerateWithInitialIds() {
        let initialIds: [EntityIdentifier] = [2, 4, 11, 3, 0, 304]
        gen = DefaultEntityIdGenerator(startProviding: initialIds)

        let generatedIds: [EntityIdentifier] = (0..<initialIds.count).map { _ in gen.nextId() }.reversed()
        XCTAssertEqual(initialIds, generatedIds)
        XCTAssertEqual(gen.nextId(), 1)
        XCTAssertEqual(gen.nextId(), 5)
        XCTAssertEqual(gen.nextId(), 6)
        XCTAssertEqual(gen.nextId(), 7)
        XCTAssertEqual(gen.nextId(), 8)
        XCTAssertEqual(gen.nextId(), 9)
        XCTAssertEqual(gen.nextId(), 10)
        XCTAssertEqual(gen.nextId(), 12)

        for i in 13...304 {
            XCTAssertEqual(gen.nextId(), EntityIdentifier(EntityIdentifier.Identifier(i)))
        }

        XCTAssertEqual(gen.nextId(), 305)
    }

    func testGeneratorMarkUnused() {
        XCTAssertEqual(gen.nextId(), 0)
        XCTAssertEqual(gen.nextId(), 1)
        XCTAssertEqual(gen.nextId(), 2)

        gen.markUnused(entityId: EntityIdentifier(1))

        XCTAssertEqual(gen.nextId(), 1)
        XCTAssertEqual(gen.nextId(), 3)
        XCTAssertEqual(gen.nextId(), 4)

        gen.markUnused(entityId: 3)
        gen.markUnused(entityId: 0)

        XCTAssertEqual(gen.nextId(), 0)
        XCTAssertEqual(gen.nextId(), 3)

        gen.markUnused(entityId: 3)

        XCTAssertEqual(gen.nextId(), 3)
        XCTAssertEqual(gen.nextId(), 5)
        XCTAssertEqual(gen.nextId(), 6)
        XCTAssertEqual(gen.nextId(), 7)
        XCTAssertEqual(gen.nextId(), 8)
    }
}
