//
//  ComponentMacroIntegrationTests.swift
//  FirebladeECSMacrosTests
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECSMacros
import Foundation
import Testing

@Component
struct MacroTransform {
    var position: Double = 0
    var parent: EntityIdentifier?
    var children: [EntityIdentifier] = []
    var slots: [String: EntityIdentifier] = [:]
    var group: Set<EntityIdentifier> = []
    @ComponentIgnored var cachedLength: Double = 0
}

final class GPUHandle: @unchecked Sendable {}

@Component(excluding: .serializable)
struct MacroRenderable {
    var handle = GPUHandle()
    var onChange: (@Sendable () -> Void)?
}

@Component
struct MacroRenamed {
    static let componentTypeName = "Renamed"
    let version: Int = 1
    var value: Int = 0
}

@Component
struct MacroMemberwise {
    var x: Double = 0
    var y: Double = 0
}

@Component
struct MacroDeclaredInit {
    var value: Int = 0

    init(value: Int) {
        self.value = value
    }
}

@Suite struct ComponentMacroIntegrationTests {
    @Test func storesComponentIndexFromTheRegistry() {
        #expect(MacroTransform.componentIndex == MacroTransform.registeredComponentIndex)
        #expect(MacroTransform.componentIndex == MacroTransform.componentIndex)
        #expect(MacroTransform.componentIndex != MacroRenderable.componentIndex)
        #expect(MacroRenderable.componentIndex != MacroRenamed.componentIndex)
    }

    @Test func structKeepsMemberwiseInitializer() throws {
        let memberwise = MacroMemberwise(x: 1, y: 2)
        #expect(memberwise.x == 1 && memberwise.y == 2)
        #expect(MacroMemberwise().x == 0)
        #expect(MacroDeclaredInit().value == 0)
        #expect(MacroDeclaredInit(value: 4).value == 4)
        let nexus = Nexus()
        #expect(try nexus.register(MacroMemberwise.self).isDefaultInitializable)
        #expect(try nexus.register(MacroDeclaredInit.self).isDefaultInitializable)
    }

    @Test func implementsProtocols() throws {
        let nexus = Nexus()
        let transform = try nexus.register(MacroTransform.self)
        #expect(transform.typeName == "FirebladeECSMacrosTests.MacroTransform")
        #expect(transform.isCloneable)
        #expect(transform.isSerializable)
        #expect(transform.isInspectable)
        #expect(transform.isDefaultInitializable)

        let renderable = try nexus.register(MacroRenderable.self)
        #expect(renderable.isCloneable)
        #expect(!renderable.isSerializable)

        #expect(try nexus.register(MacroRenamed.self).typeName == "Renamed")
    }

    @Test func defaultInitEnablesKeyPathAssignment() throws {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        entity[\MacroTransform.position] = 3
        #expect(try #require(entity.get(MacroTransform.self)).position == 3)
        #expect(nexus.isRegistered(MacroTransform.self))
    }

    @Test func inspectionSkipsIgnoredProperties() {
        #expect(MacroTransform.componentProperties.map(\.name) == ["position", "parent", "children", "slots", "group"])
        #expect(MacroRenamed.componentProperties.map(\.name) == ["version", "value"])
        #expect(!MacroRenamed.componentProperties[0].isWritable)
    }

    @Test func inspectionWritesToStructs() {
        var transform = MacroTransform()
        #expect(MacroTransform.componentProperties[0].set(4.0, on: &transform))
        #expect(transform.position == 4)
        var renamed = MacroRenamed()
        #expect(!MacroRenamed.componentProperties[0].set(2, on: &renamed))
        #expect(renamed.version == 1)
    }

    @Test func cloneIntoRemapsReferencesAndCopiesIgnoredProperties() throws {
        let source = Nexus()
        let root = source.createEntity()
        let child = source.createEntity()
        var rootTransform = MacroTransform()
        rootTransform.children = [child.identifier]
        rootTransform.cachedLength = 7
        rootTransform.slots = ["first": child.identifier]
        rootTransform.group = [child.identifier]
        var childTransform = MacroTransform()
        childTransform.parent = root.identifier
        let renderable = MacroRenderable()
        root.set(rootTransform, renderable)
        child.set(childTransform)

        let target = Nexus()
        let mapping = try source.clone(into: target)

        let clonedRoot = try #require(mapping[root.identifier])
        let clonedChild = try #require(mapping[child.identifier])
        let clonedRootTransform = try #require(clonedRoot.get(MacroTransform.self))
        #expect(clonedRootTransform.children == [clonedChild.identifier])
        #expect(clonedRootTransform.slots == ["first": clonedChild.identifier])
        #expect(clonedRootTransform.group == [clonedChild.identifier])
        #expect(clonedRootTransform.cachedLength == 7)
        #expect(try #require(clonedChild.get(MacroTransform.self)).parent == clonedRoot.identifier)
        #expect(try #require(clonedRoot.get(MacroRenderable.self)).handle === renderable.handle)
    }

    @Test func snapshotRoundTrip() throws {
        let source = Nexus()
        let root = source.createEntity()
        let child = source.createEntity()
        var rootTransform = MacroTransform()
        rootTransform.position = 2
        rootTransform.children = [child.identifier]
        rootTransform.cachedLength = 7
        var childTransform = MacroTransform()
        childTransform.parent = root.identifier
        root.set(rootTransform, MacroRenderable(), MacroRenamed())
        child.set(childTransform)

        var encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try source.encodeSnapshot(using: &encoder, handling: .skip)
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("cachedLength"))
        #expect(!json.contains("version"))
        #expect(json.contains(#""Renamed":{"value":0}"#))

        let target = Nexus()
        try target.register([MacroTransform.self, MacroRenamed.self])
        var decoder = JSONDecoder()
        let mapping = try target.decodeSnapshot(from: data, using: &decoder)

        let importedRoot = try #require(mapping[root.identifier])
        let importedChild = try #require(mapping[child.identifier])
        let importedTransform = try #require(importedRoot.get(MacroTransform.self))
        #expect(importedTransform.position == 2)
        #expect(importedTransform.children == [importedChild.identifier])
        #expect(importedTransform.cachedLength == 0)
        #expect(try #require(importedChild.get(MacroTransform.self)).parent == importedRoot.identifier)
        #expect(importedRoot.get(MacroRenderable.self) == nil)
        #expect(importedRoot.has(MacroRenamed.self))
    }
}
