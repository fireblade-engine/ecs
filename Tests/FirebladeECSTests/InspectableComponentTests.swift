//
//  InspectableComponentTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECS
import Testing

struct InspectedTransform: InspectableComponent, RegistrableComponent, Sendable {
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
        var component = InspectedTransform()
        let property = InspectedTransform.componentProperties[0]
        #expect(property.value(of: component) as? Double == 1)

        let writable = try #require(property.keyPath as? WritableKeyPath<InspectedTransform, Double>)
        component[keyPath: writable] = 5
        #expect(component.position == 5)
    }

    @Test func setsWritablePropertiesOnACopy() {
        var component = InspectedTransform()
        let position = InspectedTransform.componentProperties[0]
        let name = InspectedTransform.componentProperties[1]

        #expect(position.set(5.0, on: &component))
        #expect(component.position == 5)
        #expect(!position.set("wrong type", on: &component))
        #expect(component.position == 5)
        #expect(!name.set("renamed", on: &component))
        #expect(component.name == "transform")
    }

    @Test(arguments: Nexus.StorageKind.allCases) func typeErasedInspection(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity(with: InspectedTransform())
        let component = try #require(entity.makeComponentsIterator().first(where: { _ in true }))
        let inspectable = try #require(component as? any InspectableComponent)

        let inspected = inspectable.inspectedProperties
        #expect(inspected.map(\.name) == ["position", "name"])
        #expect(inspected[1].value as? String == "transform")
        #expect(try #require(nexus.componentType(for: InspectedTransform.identifier)).isInspectable)
    }
}
