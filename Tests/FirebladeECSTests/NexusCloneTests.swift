//
//  NexusCloneTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 08.10.26.
//

@testable import FirebladeECS
import Testing

final class SharedPayload: @unchecked Sendable {}

struct CloneValue: CloneableComponent, Sendable {
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

struct CloneParent: CloneableComponent, Sendable {
    var parent: Entity?

    init(parent: Entity?) {
        self.parent = parent
    }

    func clone(context: ComponentCloneContext) -> CloneParent {
        CloneParent(parent: context.clone(parent))
    }
}

struct CloneChildren: CloneableComponent, Sendable {
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
    @Test(arguments: Nexus.StorageKind.allCases) func cloneEntityCopiesValuesAndSharesReferences(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let payload = SharedPayload()
        let source = nexus.createEntity(with: CloneValue(value: 3, payload: payload))

        let clone = try source.clone()

        #expect(clone != source)
        #expect(nexus.numEntities == 2)
        let original = try #require(source.get(CloneValue.self))
        var cloned = try #require(clone.get(CloneValue.self))
        #expect(cloned.value == 3)
        #expect(cloned.payload === payload)

        // the clone is an independent copy
        clone.modify(CloneValue.self) { $0.value = 4 }
        cloned.value = 5
        #expect(source.get(CloneValue.self)?.value == original.value)
        #expect(original.value == 3)
        #expect(clone.get(CloneValue.self)?.value == 4)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func cloneEntityRemapsSelfReferenceAndKeepsExternal(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
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

    @Test(arguments: Nexus.StorageKind.allCases) func cloneEntitiesRemapsReferencesWithinGroup(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
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

    @Test(arguments: Nexus.StorageKind.allCases) func cloneIntoTargetRemapsAllReferences(_ storage: Nexus.StorageKind) throws {
        let source = Nexus(storage: storage)
        let root = source.createEntity()
        let child = source.createEntity(with: CloneParent(parent: root), CloneValue(value: 1, payload: SharedPayload()))
        root.set(CloneChildren(children: [child], self_: root.identifier))
        source.createEntity()

        let target = Nexus(storage: storage)
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

    @Test(arguments: Nexus.StorageKind.allCases) func nonCloneableComponentThrowsWithoutSideEffects(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let cloneable = nexus.createEntity(with: CloneValue(value: 1, payload: SharedPayload()))
        let plain = nexus.createEntity(with: Position(x: 1, y: 2))

        #expect(throws: ComponentCloneError.notCloneable(typeName: "FirebladeECSTests.Position")) {
            try nexus.clone(entities: [cloneable, plain])
        }
        #expect(nexus.numEntities == 2)

        let target = Nexus(storage: storage)
        #expect(throws: ComponentCloneError.notCloneable(typeName: "FirebladeECSTests.Position")) {
            try nexus.clone(into: target)
        }
        #expect(target.numEntities == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func unknownEntityThrows(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity()
        nexus.destroy(entity: entity)
        #expect(throws: ComponentCloneError.unknownEntity(entity.identifier)) {
            try nexus.clone(entity: entity)
        }
    }

    @Test(arguments: Nexus.StorageKind.allCases) func cloneContextIdentityForUnmappedValues(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let context = ComponentCloneContext(nexus: nexus, mapping: [1: 5])
        #expect(context.clone(42) == 42)
        #expect(context.clone("text") == "text")
        #expect(context.clone(EntityIdentifier(index: 1, generation: 0)) == 5)
        #expect(context.clone(EntityIdentifier(index: 2, generation: 0)) == 2)
        #expect(context.clone(Optional(EntityIdentifier(index: 1, generation: 0))) == 5)
        #expect(context.clone([EntityIdentifier(index: 1, generation: 0), 2]) == [5, 2])
        #expect(context.clone(Set<EntityIdentifier>([1, 2])) == [5, 2])
        let entity = nexus.createEntity() // the first entity has index 1
        #expect(context.clone(["a": entity])["a"]?.identifier == 5)
    }
}
