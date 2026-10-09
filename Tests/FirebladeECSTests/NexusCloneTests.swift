//
//  NexusCloneTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

@testable import FirebladeECS
import Testing

final class SharedPayload: @unchecked Sendable {}

final class CloneValue: CloneableComponent, @unchecked Sendable {
    var value: Int
    let payload: SharedPayload

    init(value: Int, payload: SharedPayload) {
        self.value = value
        self.payload = payload
    }

    func clone(context: ComponentCloneContext) -> CloneValue {
        CloneValue(value: context.clone(value), payload: context.clone(payload))
    }
}

final class CloneParent: CloneableComponent, @unchecked Sendable {
    var parent: Entity?

    init(parent: Entity?) {
        self.parent = parent
    }

    func clone(context: ComponentCloneContext) -> CloneParent {
        CloneParent(parent: context.clone(parent))
    }
}

final class CloneChildren: CloneableComponent, @unchecked Sendable {
    var children: [Entity]
    var self_: EntityIdentifier

    init(children: [Entity], self_: EntityIdentifier) {
        self.children = children
        self.self_ = self_
    }

    func clone(context: ComponentCloneContext) -> CloneChildren {
        CloneChildren(children: context.clone(children), self_: context.clone(self_))
    }
}

@Suite struct NexusCloneTests {
    @Test func cloneEntityCopiesValuesAndSharesReferences() throws {
        let nexus = Nexus()
        let payload = SharedPayload()
        let source = nexus.createEntity(with: CloneValue(value: 3, payload: payload))

        let clone = try source.clone()

        #expect(clone != source)
        #expect(nexus.numEntities == 2)
        let original = try #require(source.get(CloneValue.self))
        let cloned = try #require(clone.get(CloneValue.self))
        #expect(cloned !== original)
        #expect(cloned.value == 3)
        #expect(cloned.payload === payload)

        cloned.value = 4
        #expect(original.value == 3)
    }

    @Test func cloneEntityRemapsSelfReferenceAndKeepsExternal() throws {
        let nexus = Nexus()
        let external = nexus.createEntity()
        let source = nexus.createEntity()
        source.set(CloneParent(parent: external), CloneChildren(children: [external, source], self_: source.identifier))

        let clone = try nexus.clone(entity: source)

        let parent = try #require(clone.get(CloneParent.self))
        #expect(parent.parent == external)
        let children = try #require(clone.get(CloneChildren.self))
        #expect(children.children == [external, clone])
        #expect(children.self_ == clone.identifier)
    }

    @Test func cloneEntitiesRemapsReferencesWithinGroup() throws {
        let nexus = Nexus()
        let root = nexus.createEntity()
        let child = nexus.createEntity(with: CloneParent(parent: root))
        root.set(CloneChildren(children: [child], self_: root.identifier))

        let clones = try nexus.clone(entities: [root, child, root])

        #expect(clones.count == 3)
        #expect(clones[0] == clones[2])
        #expect(nexus.numEntities == 4)
        let clonedChildren = try #require(clones[0].get(CloneChildren.self))
        #expect(clonedChildren.children == [clones[1]])
        let clonedParent = try #require(clones[1].get(CloneParent.self))
        #expect(clonedParent.parent == clones[0])
    }

    @Test func cloneIntoTargetRemapsAllReferences() throws {
        let source = Nexus()
        let root = source.createEntity()
        let child = source.createEntity(with: CloneParent(parent: root), CloneValue(value: 1, payload: SharedPayload()))
        root.set(CloneChildren(children: [child], self_: root.identifier))
        source.createEntity()

        let target = Nexus()
        let mapping = try source.clone(into: target)

        #expect(target.numEntities == 3)
        #expect(target.numComponents == 3)
        let clonedRoot = try #require(mapping[root.identifier])
        let clonedChild = try #require(mapping[child.identifier])
        #expect(try #require(clonedRoot.get(CloneChildren.self)).children == [clonedChild])
        #expect(try #require(clonedChild.get(CloneParent.self)).parent == clonedRoot)
        #expect(try #require(clonedChild.get(CloneValue.self)).value == 1)
        #expect(target.family(requires: CloneParent.self).count == 1)
    }

    @Test func nonCloneableComponentThrowsWithoutSideEffects() {
        let nexus = Nexus()
        let cloneable = nexus.createEntity(with: CloneValue(value: 1, payload: SharedPayload()))
        let plain = nexus.createEntity(with: Position(x: 1, y: 2))

        #expect(throws: ComponentCloneError.notCloneable(typeName: "FirebladeECSTests.Position")) {
            try nexus.clone(entities: [cloneable, plain])
        }
        #expect(nexus.numEntities == 2)

        let target = Nexus()
        #expect(throws: ComponentCloneError.notCloneable(typeName: "FirebladeECSTests.Position")) {
            try nexus.clone(into: target)
        }
        #expect(target.numEntities == 0)
    }

    @Test func unknownEntityThrows() {
        let nexus = Nexus()
        let entity = nexus.createEntity()
        nexus.destroy(entity: entity)
        #expect(throws: ComponentCloneError.unknownEntity(entity.identifier)) {
            try nexus.clone(entity: entity)
        }
    }

    @Test func cloneContextIdentityForUnmappedValues() {
        let nexus = Nexus()
        let context = ComponentCloneContext(nexus: nexus, mapping: [1: 5])
        #expect(context.clone(42) == 42)
        #expect(context.clone("text") == "text")
        #expect(context.clone(EntityIdentifier(1)) == 5)
        #expect(context.clone(EntityIdentifier(2)) == 2)
        #expect(context.clone(Optional(EntityIdentifier(1))) == 5)
        #expect(context.clone([EntityIdentifier(1), 2]) == [5, 2])
        #expect(context.clone(Set<EntityIdentifier>([1, 2])) == [5, 2])
        let entity = nexus.entity(from: 1)
        #expect(context.clone(["a": entity])["a"]?.identifier == 5)
    }
}
