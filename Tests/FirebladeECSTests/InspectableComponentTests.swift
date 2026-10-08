//
//  InspectableComponentTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECS
import Testing

final class InspectedTransform: InspectableComponent, RegistrableComponent, @unchecked Sendable {
    var position: Double = 1
    let name: String = "transform"

    static var componentProperties: [ComponentProperty<InspectedTransform>] {
        [
            ComponentProperty(name: "position", keyPath: \InspectedTransform.position),
            ComponentProperty(name: "name", keyPath: \InspectedTransform.name)
        ]
    }
}

@Suite struct InspectableComponentTests {
    @Test func describesProperties() {
        let properties = InspectedTransform.componentProperties
        #expect(properties.map(\.name) == ["position", "name"])
        #expect(ObjectIdentifier(properties[0].valueType) == ObjectIdentifier(Double.self))
        #expect(properties[0].isWritable)
        #expect(ObjectIdentifier(properties[1].valueType) == ObjectIdentifier(String.self))
        #expect(!properties[1].isWritable)
    }

    @Test func readsAndWritesThroughKeyPaths() throws {
        let component = InspectedTransform()
        let property = InspectedTransform.componentProperties[0]
        #expect(property.value(of: component) as? Double == 1)

        let writable = try #require(property.keyPath as? ReferenceWritableKeyPath<InspectedTransform, Double>)
        component[keyPath: writable] = 5
        #expect(component.position == 5)
    }

    @Test func typeErasedInspection() throws {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: InspectedTransform())
        let component = try #require(entity.makeComponentsIterator().first(where: { _ in true }))
        let inspectable = try #require(component as? any InspectableComponent)

        let inspected = inspectable.inspectedProperties
        #expect(inspected.map(\.name) == ["position", "name"])
        #expect(inspected[1].value as? String == "transform")
        #expect(try #require(nexus.componentType(for: InspectedTransform.identifier)).isInspectable)
    }
}
