//
//  ParameterPackTests.swift
//  FirebladeECSTests
//
//  Created by Conductor on 2026-02-13.
//

import Testing
@testable import FirebladeECS

struct ParameterPackTests {

    struct FamilyPack<each C: Component> {
        let components: (repeat each C)

        init(_ components: repeat each C) {
            self.components = (repeat each components)
        }

        func forEach(_ body: (repeat each C) -> Void) {
            body(repeat each components)
        }
    }

    @Test func testParameterPackIteration() {
        final class Position: Component, @unchecked Sendable { 
            var x: Int 
            var y: Int 
            init(x: Int, y: Int) { self.x = x; self.y = y }
        }
        final class Velocity: Component, @unchecked Sendable { 
            var dx: Int 
            var dy: Int 
            init(dx: Int, dy: Int) { self.dx = dx; self.dy = dy }
        }

        let pos = Position(x: 10, y: 20)
        let vel = Velocity(dx: 1, dy: 1)

        let family = FamilyPack(pos, vel)

        family.forEach { (p: Position, v: Velocity) in
            #expect(p.x == 10)
            #expect(v.dx == 1)
        }
    }
}
