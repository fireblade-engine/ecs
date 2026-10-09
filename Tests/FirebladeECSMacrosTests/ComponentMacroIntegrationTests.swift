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
final class MacroTransform: @unchecked Sendable {
    var position: Double = 0
    var parent: Entity?
    var children: [Entity] = []
    @ComponentIgnored var cachedLength: Double = 0
}

final class GPUHandle: @unchecked Sendable {}

@Component(excluding: .serializable)
final class MacroRenderable: @unchecked Sendable {
    var handle = GPUHandle()
    var onChange: (() -> Void)?
}

@Component
final class MacroRenamed: @unchecked Sendable {
    static let componentTypeName = "Renamed"
    let version: Int = 1
    var value: Int = 0
}

@Suite struct ComponentMacroIntegrationTests {
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
        #expect(MacroTransform.componentProperties.map(\.name) == ["position", "parent", "children"])
        #expect(MacroRenamed.componentProperties.map(\.name) == ["version", "value"])
        #expect(!MacroRenamed.componentProperties[0].isWritable)
    }

    @Test func cloneIntoRemapsReferencesAndCopiesIgnoredProperties() throws {
        let source = Nexus()
        let root = source.createEntity()
        let child = source.createEntity()
        let rootTransform = MacroTransform()
        rootTransform.children = [child]
        rootTransform.cachedLength = 7
        let childTransform = MacroTransform()
        childTransform.parent = root
        let renderable = MacroRenderable()
        root.set(rootTransform, renderable)
        child.set(childTransform)

        let target = Nexus()
        let mapping = try source.clone(into: target)

        let clonedRoot = try #require(mapping[root.identifier])
        let clonedChild = try #require(mapping[child.identifier])
        let clonedRootTransform = try #require(clonedRoot.get(MacroTransform.self))
        #expect(clonedRootTransform !== rootTransform)
        #expect(clonedRootTransform.children == [clonedChild])
        #expect(clonedRootTransform.cachedLength == 7)
        #expect(try #require(clonedChild.get(MacroTransform.self)).parent == clonedRoot)
        #expect(try #require(clonedRoot.get(MacroRenderable.self)).handle === renderable.handle)
    }

    @Test func snapshotRoundTrip() throws {
        let source = Nexus()
        let root = source.createEntity()
        let child = source.createEntity()
        let rootTransform = MacroTransform()
        rootTransform.position = 2
        rootTransform.children = [child]
        rootTransform.cachedLength = 7
        let childTransform = MacroTransform()
        childTransform.parent = root
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
        #expect(importedTransform.children == [importedChild])
        #expect(importedTransform.cachedLength == 0)
        #expect(try #require(importedChild.get(MacroTransform.self)).parent == importedRoot)
        #expect(importedRoot.get(MacroRenderable.self) == nil)
        #expect(importedRoot.has(MacroRenamed.self))
    }
}
