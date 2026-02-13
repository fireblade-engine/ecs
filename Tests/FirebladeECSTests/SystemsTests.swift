//
//  SystemsTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 10.05.18.
//

@testable import FirebladeECS
import Testing

@Suite struct SystemsTests {
    private func createDefaultEntity(in nexus: Nexus) {
        let e = nexus.createEntity()
        e.assign(Position(x: 1, y: 2))
        e.assign(Color())
    }

    private func batchCreateEntities(in nexus: Nexus, count: Int) {
        for _ in 0..<count {
            createDefaultEntity(in: nexus)
        }
    }

    private func batchDestroyEntities(in nexus: Nexus, count: Int) {
        let family = nexus.family(requires: Position.self)

        family
            .entities
            .prefix(count)
            .forEach { (entity: Entity) in
                entity.destroy()
            }
    }

    @Test func systemsUpdate() {
        let nexus = Nexus()
        let colorSystem = ColorSystem(nexus: nexus)
        let positionSystem = PositionSystem(nexus: nexus)
        let num: Int = 10_000

        colorSystem.update()
        positionSystem.update()

        let posTraits = positionSystem.positions.traits

        #expect(nexus.numEntities == 0)
        #expect(colorSystem.colors.memberIds.count == 0)
        #expect(positionSystem.positions.memberIds.count == 0)
        #expect(nexus.familyMembersByTraits[posTraits]?.count == 0)

        batchCreateEntities(in: nexus, count: num)

        #expect(nexus.numEntities == num)
        #expect(nexus.familyMembersByTraits[posTraits]?.count == num)
        #expect(colorSystem.colors.memberIds.count == num)
        #expect(positionSystem.positions.memberIds.count == num)

        colorSystem.update()
        positionSystem.update()

        #expect(nexus.numEntities == num)
        #expect(nexus.familyMembersByTraits[posTraits]?.count == num)
        #expect(colorSystem.colors.memberIds.count == num)
        #expect(positionSystem.positions.memberIds.count == num)

        batchCreateEntities(in: nexus, count: num)

        #expect(nexus.numEntities == num * 2)
        #expect(nexus.familyMembersByTraits[posTraits]?.count == num * 2)
        #expect(colorSystem.colors.memberIds.count == num * 2)
        #expect(positionSystem.positions.memberIds.count == num * 2)

        colorSystem.update()
        positionSystem.update()

        #expect(nexus.numEntities == num * 2)
        #expect(nexus.familyMembersByTraits[posTraits]?.count == num * 2)
        #expect(colorSystem.colors.memberIds.count == num * 2)
        #expect(positionSystem.positions.memberIds.count == num * 2)

        batchDestroyEntities(in: nexus, count: num)

        #expect(nexus.familyMembersByTraits[posTraits]?.count == num)
        #expect(nexus.numEntities == num)
        #expect(colorSystem.colors.memberIds.count == num)
        #expect(positionSystem.positions.memberIds.count == num)

        colorSystem.update()
        positionSystem.update()

        #expect(nexus.familyMembersByTraits[posTraits]?.count == num)
        #expect(nexus.numEntities == num)
        #expect(colorSystem.colors.memberIds.count == num)
        #expect(positionSystem.positions.memberIds.count == num)

        batchCreateEntities(in: nexus, count: num)

        #expect(nexus.familyMembersByTraits[posTraits]?.count == num * 2)
        #expect(nexus.numEntities == num * 2)
        #expect(colorSystem.colors.memberIds.count == num * 2)
        #expect(positionSystem.positions.memberIds.count == num * 2)
    }
}
