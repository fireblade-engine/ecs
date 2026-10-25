//
//  ComponentIdentifierTests.swift
//
//
//  Created by Christian Treffs on 05.10.19.
//
@testable import FirebladeECS
import Testing

private final class CustomIdentifierComponent: Component {
    static var identifier: ComponentIdentifier { ComponentIdentifier(id: 42) }
}

private func genericIdentifier<C: Component>(of _: C.Type) -> ComponentIdentifier {
    C.identifier
}

@Suite struct ComponentIdentifierTests {
    @Test func customStaticIdentifierIsUsedInGenericContext() {
        #expect(genericIdentifier(of: CustomIdentifierComponent.self) == ComponentIdentifier(id: 42))
        #expect(CustomIdentifierComponent().identifier == ComponentIdentifier(id: 42))
    }

    @Test func defaultStaticIdentifierIsUsedInGenericContext() {
        #expect(genericIdentifier(of: Position.self) == ComponentIdentifier(Position.self))
    }

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
