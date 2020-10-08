//
//  TypedFamilyPerformanceTests.swift
//  FirebladeECSPerformanceTests
//
//  Created by Christian Treffs on 29.09.18.
//

import FirebladeECS
import XCTest

class TypedFamilyPerformanceTests: XCTestCase {
    let numEntities: Int = 10_000
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()

        for i in 0..<numEntities {
            nexus.createEntity().assign(Position(x: 1 + i, y: 2 + i),
                                        Name(name: "myName\(i)"),
                                        Velocity(a: 3.14),
                                        EmptyComponent(),
                                        Color())
        }
    }

    override func tearDown() {
        nexus = nil
        super.tearDown()
    }

    /// release: 0.007 sec
    /// debug:   0.017 sec
    func testMeasureTraitMatching() {
        let a = nexus.createEntity()
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())

        let isMatch = nexus.family(requiresAll: Position.self, Velocity.self,
                                   excludesAll: Party.self)

        measure {
            for _ in 0..<10_000 {
                let success = isMatch.canBecomeMember(a)
                XCTAssert(success)
            }
        }
    }

    /// release: 0.001 sec
    /// debug:   0.008 sec
    func testPerformanceTypedFamilyEntities() {
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entities
                .forEach { (entity: Entity) in
                    _ = entity

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// debug: 0.004 sec
    func testPerformanceArray() {
        let positions = [Position](repeating: Position(x: Int.random(in: 0...10), y: Int.random(in: 0...10)), count: numEntities)

        var loopCount: Int = 0

        measure {
            positions
                .forEach { (position: Position) in
                    _ = position
                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, numEntities * 10)
    }

    /// release: 0.002 sec
    /// debug:   0.010 sec
    func testPerformanceTypedFamilyOneComponent() {
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .forEach { (position: Position) in
                    _ = position

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.002 sec
    /// debug:   0.016 sec
    func testPerformanceTypedFamilyEntityOneComponent() {
        let family = nexus.family(requires: Position.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position) in
                    _ = entity
                    _ = position

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.002 sec
    /// debug:   0.016 sec
    func testPerformanceTypedFamilyTwoComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .forEach { (position: Position, velocity: Velocity) in
                    _ = position
                    _ = velocity

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.003 sec
    func testPerformanceTypedFamilyEntityTwoComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position, velocity: Velocity) in
                    _ = entity
                    _ = position
                    _ = velocity

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.004 sec
    func testPerformanceTypedFamilyThreeComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .forEach { (position: Position, velocity: Velocity, name: Name) in
                    _ = position
                    _ = velocity
                    _ = name

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.004 sec
    func testPerformanceTypedFamilyEntityThreeComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name) in
                    _ = entity
                    _ = position
                    _ = velocity
                    _ = name

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.004 sec
    func testPerformanceTypedFamilyFourComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .forEach { (position: Position, velocity: Velocity, name: Name, color: Color) in
                    _ = position
                    _ = velocity
                    _ = name
                    _ = color

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release:  0.005 sec
    func testPerformanceTypedFamilyEntityFourComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name, color: Color) in
                    _ = entity
                    _ = position
                    _ = velocity
                    _ = name
                    _ = color

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.005 sec
    func testPerformanceTypedFamilyFiveComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family.forEach { (position: Position, velocity: Velocity, name: Name, color: Color, empty: EmptyComponent) in
                _ = position
                _ = velocity
                _ = name
                _ = color
                _ = empty

                loopCount += 1
            }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }

    /// release: 0.006 sec
    func testPerformanceTypedFamilyEntityFiveComponents() {
        let family = nexus.family(requiresAll: Position.self, Velocity.self, Name.self, Color.self, EmptyComponent.self, excludesAll: Party.self)

        XCTAssertEqual(family.count, numEntities)
        XCTAssertEqual(nexus.numEntities, numEntities)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numComponents, numEntities * 5)

        var loopCount: Int = 0

        measure {
            family
                .entityAndComponents
                .forEach { (entity: Entity, position: Position, velocity: Velocity, name: Name, color: Color, empty: EmptyComponent) in
                    _ = entity
                    _ = position
                    _ = velocity
                    _ = name
                    _ = color
                    _ = empty

                    loopCount += 1
                }
        }

        XCTAssertEqual(loopCount, family.count * 10)
    }
}
