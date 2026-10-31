//
//  EntityCreationTests.swift
//
//
//  Created by Christian Treffs on 30.07.20.
//

@testable import FirebladeECS
import Testing

@Suite struct EntityCreationTests {
    @Test(arguments: Nexus.StorageKind.allCases) func createEntityOneComponent(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)
        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
        }

        #expect(entity[\Position.x] == 1)
        #expect(entity[\Position.y] == 2)

        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 1)
        #expect(nexus.numFamilies == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func createEntityMultipleComponents(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)

        let entity = nexus.createEntity {
            Position(x: 1, y: 2)
            Name(name: "Hello")
        }

        #expect(entity[\Position.x] == 1)
        #expect(entity[\Position.y] == 2)

        #expect(entity[\Name.name] == "Hello")

        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 2)
        #expect(nexus.numFamilies == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func bulkCreateEntitiesOneComponent(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)

        let entities = nexus.createEntities(count: 100) { ctx in
            Velocity(a: Float(ctx.index))
        }

        #expect(entities[0][\Velocity.a] == 0)
        #expect(entities[99][\Velocity.a] == 99)

        #expect(nexus.numEntities == 100)
        #expect(nexus.numComponents == 100)
        #expect(nexus.numFamilies == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func bulkCreateEntitiesMultipleComponents(_ storage: Nexus.StorageKind) throws {
        let nexus = Nexus(storage: storage)

        let entities = nexus.createEntities(count: 100) { ctx in
            Position(x: ctx.index, y: ctx.index)
            Name(name: "\(ctx.index)")
        }

        #expect(entities[0][\Position.x] == 0)
        #expect(entities[0][\Position.y] == 0)
        #expect(entities[0][\Name.name] == "0")
        #expect(entities[99][\Position.x] == 99)
        #expect(entities[99][\Position.y] == 99)
        #expect(entities[99][\Name.name] == "99")

        #expect(nexus.numEntities == 100)
        #expect(nexus.numComponents == 200)
        #expect(nexus.numFamilies == 0)
    }
}

private final class CreationRecorder: NexusEventDelegate, @unchecked Sendable {
    private(set) var names: [String] = []
    func reset() { names.removeAll() }
    var subscribedEvents: NexusEventMask { .all }
    func nexusEvent(_ event: NexusEvent) {
        switch event {
        case is EntityCreated: names.append("created")
        case let added as ComponentAdded: names.append("added \(added.component == Comp1.identifier ? "1" : added.component == Comp2.identifier ? "2" : "3")")
        case is FamilyMemberAdded: names.append("member")
        default: names.append("other")
        }
    }

    func nexusNonFatalError(_: String) {}
}

@Suite struct EntityCreationEquivalenceTests {
    struct Observed {
        let all: Family<Comp1>
        let both: Family<Comp1, Comp2>
        let noThree: Family<Comp1, Comp2>
    }

    private static func observe(_ nexus: Nexus) -> Observed {
        Observed(
            all: nexus.family(requiresAll: Comp1.self),
            both: nexus.family(requiresAll: Comp1.self, Comp2.self),
            noThree: nexus.family(requiresAll: Comp1.self, Comp2.self, excludesAll: Comp3.self)
        )
    }

    @Test(arguments: Nexus.StorageKind.allCases) func createdEntitiesMatchWithAndWithoutDelegate(_ storage: Nexus.StorageKind) {
        let plain = Nexus(storage: storage)
        let observed = Nexus(storage: storage)
        let recorder = CreationRecorder()
        observed.delegate = recorder
        let families = [Self.observe(plain), Self.observe(observed)]
        for nexus in [plain, observed] {
            nexus.createEntity(with: Comp1(1))
            nexus.createEntity(with: Comp1(2), Comp2(2))
            nexus.createEntity(with: Comp2(3), Comp3(3), Comp1(3))
            nexus.createEntity(with: [Comp3(4) as Component, Comp1(4), Comp2(4)])
            nexus.createEntity(with: Comp1(5), Comp1(6)) // the later value wins
            nexus.createEntity(with: Comp1(7) as Component, Comp2(7))
        }
        #expect(families[0].all.entities.map(\.identifier) == families[1].all.entities.map(\.identifier))
        #expect(families[0].both.entities.map(\.identifier) == families[1].both.entities.map(\.identifier))
        #expect(families[0].noThree.entities.map(\.identifier) == families[1].noThree.entities.map(\.identifier))
        #expect(families[0].all.count == 6)
        #expect(families[0].both.count == 4)
        #expect(families[0].noThree.count == 2)
        #expect(plain.numComponents == observed.numComponents)
        for entity in families[0].all.entities {
            let twin = Entity(nexus: observed, id: entity.identifier)
            #expect(entity.get(Comp1.self) == twin.get(Comp1.self))
            #expect(entity.get(Comp2.self) == twin.get(Comp2.self))
            #expect(entity.get(Comp3.self) == twin.get(Comp3.self))
        }
        #expect(plain.family(requiresAll: Comp1.self).entities.contains { $0.get(Comp1.self) == Comp1(6) })
        // the entities keep working after the direct placement
        for entity in families[0].all.entities {
            entity.remove(Comp1.self)
            entity.set(Comp3(0))
        }
        #expect(families[0].all.count == 0)
    }

    @Test(arguments: Nexus.StorageKind.allCases) func delegateStillSeesComponentsGainedOneByOne(_ storage: Nexus.StorageKind) {
        let nexus = Nexus(storage: storage)
        let recorder = CreationRecorder()
        nexus.delegate = recorder
        _ = Self.observe(nexus)
        recorder.reset()
        nexus.createEntity(with: Comp1(1), Comp2(2))
        #expect(recorder.names == ["created", "added 1", "added 2", "member", "member", "member"])
    }
}
