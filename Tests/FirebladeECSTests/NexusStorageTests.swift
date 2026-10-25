//
//  NexusStorageTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Tag127: Component, Sendable {
    static let componentIndex = 127
}

private struct Tag128: Component, Sendable {
    static let componentIndex = 128
}

private struct Tag300: Component, Sendable {
    static let componentIndex = 300
}

@Suite struct NexusStorageTests {
    @Test func defaultStorageIsTheSparseSet() {
        #expect(Nexus.StorageKind.default == .sparseSet)
        #expect(Nexus.StorageKind.allCases == [.sparseSet])
    }

    @Test(arguments: Nexus.StorageKind.allCases)
    func nexusWorksOnEveryStorage(_ kind: Nexus.StorageKind) {
        let nexus = Nexus(storage: kind)
        let family = nexus.family(requiresAll: Position.self, Name.self, excludesAll: Comp1.self)
        let entity = nexus.createEntity(with: Position(x: 1, y: 2), Name(name: "a"))
        let other = nexus.createEntity(with: Position(x: 3, y: 4), Name(name: "b"), Comp1(1))
        #expect(family.entities.map(\.identifier) == [entity.identifier])
        #expect(entity.get(Position.self)?.x == 1)
        #expect(nexus.numComponents == 5)
        other.remove(Comp1.self)
        #expect(family.count == 2)
        nexus.destroy(entity: entity)
        #expect(family.count == 1)
        #expect(nexus.numComponents == 2)
    }

    @Test func familiesSpanTheInlineBoundaryOfTheComponentMask() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Tag127.self, Tag300.self, excludesAll: Tag128.self)
        let match = nexus.createEntity(with: Tag127(), Tag300())
        let excluded = nexus.createEntity(with: Tag127(), Tag128(), Tag300())
        let incomplete = nexus.createEntity(with: Tag127(), Tag128())
        #expect(family.entities.map(\.identifier) == [match.identifier])
        #expect(family.canBecomeMember(match))
        #expect(!family.canBecomeMember(excluded))
        #expect(!family.canBecomeMember(incomplete))

        excluded.remove(Tag128.self)
        #expect(family.entities.map(\.identifier) == [match.identifier, excluded.identifier])
        match.remove(Tag300.self)
        #expect(family.entities.map(\.identifier) == [excluded.identifier])
        #expect(match.numComponents == 1)
        #expect(Set(excluded.makeComponentsIterator().map(\.identifier)) == [Tag127.identifier, Tag300.identifier])
    }

    @Test func familyCreatedAfterEntitiesFindsComponentsAboveTheInlineBoundary() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: Tag300())
        let family = nexus.family(requires: Tag300.self)
        #expect(family.entities.map(\.identifier) == [entity.identifier])
    }

    @Test func traitsFromIdentifiersResolveThroughTheStorage() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: Position(x: 1, y: 1))
        let traits = FamilyTraitSet(requiresAll: [Position.identifier], excludesAll: [Name.identifier])
        #expect(nexus.canBecomeMember(entity, in: traits))
        // required component without storage: nobody can match
        let unknown = FamilyTraitSet(requiresAll: [ComponentIdentifier(id: 12345)], excludesAll: [])
        #expect(!nexus.canBecomeMember(entity, in: unknown))
        // excluded component without storage excludes nothing
        let excludesUnknown = FamilyTraitSet(requiresAll: [Position.identifier], excludesAll: [ComponentIdentifier(id: 12345)])
        #expect(nexus.canBecomeMember(entity, in: excludesUnknown))
        entity.set(Name(name: "x"))
        #expect(!nexus.canBecomeMember(entity, in: traits))
    }

    @Test func clearDropsEntitiesComponentsAndFamilies() {
        let nexus = Nexus()
        let family = nexus.family(requires: Position.self)
        nexus.createEntity(with: Position(x: 1, y: 1))
        nexus.clear()
        #expect(nexus.numEntities == 0)
        #expect(nexus.numComponents == 0)
        #expect(nexus.numFamilies == 0)
        #expect(family.count == 0)
        // the nexus stays usable
        let entity = nexus.createEntity(with: Position(x: 2, y: 2))
        #expect(entity.get(Position.self)?.x == 2)
    }

    @Test func componentIdentifiersOfAnEntityComeFromTheStorage() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: Position(x: 1, y: 1), Name(name: "n"))
        #expect(nexus.get(components: entity.identifier) == [Position.identifier, Name.identifier])
        #expect(nexus.has(componentId: Position.identifier, entityId: entity.identifier))
        #expect(!nexus.has(componentId: Comp1.identifier, entityId: entity.identifier))
        #expect(nexus.count(components: entity.identifier) == 2)
        nexus.destroy(entity: entity)
        #expect(nexus.get(components: entity.identifier) == nil)
    }
}
