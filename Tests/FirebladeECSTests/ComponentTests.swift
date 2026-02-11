//
//  ComponentTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 21.10.17.
//

import FirebladeECS
import Testing

@Suite struct ComponentTests {
    @Test func componentIdentifier() {
        #expect(Position.identifier == Position.identifier)
        #expect(Velocity.identifier == Velocity.identifier)
        #expect(Velocity.identifier != Position.identifier)

        let p1 = Position(x: 1, y: 2)
        let v1 = Velocity(a: 3.14)
        #expect(p1.identifier == Position.identifier)
        #expect(v1.identifier == Velocity.identifier)
        #expect(v1.identifier != p1.identifier)
    }
}
