//
//  ComponentIdentifierTests.swift
//
//
//  Created by Christian Treffs on 05.10.19.
//
import FirebladeECS
import Testing

@Suite struct ComponentIdentifierTests {
    @Test func mirrorAsStableIdentifier() {
        let m = String(reflecting: Position.self)
        let identifier: String = m
        #expect(identifier == "FirebladeECSTests.Position")
    }

    @Test func stringDescribingAsStableIdentifier() {
        let s = String(describing: Position.self)
        let identifier: String = s
        #expect(identifier == "Position")
    }
}
