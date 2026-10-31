import FirebladeECS
import Testing
@testable import ECSBenchmark

@Suite
struct ReferenceUpdateTests {
    @Test
    func xoshiro128HasFixedSequences() {
        var generator = ReferenceXoshiro128(seed: 0)
        let values = (0 ..< 6).map { _ in generator.next() }
        #expect(values == [28_800, 5_760, 14_791_680, 168_174_720, 2_334_461_512, 3_045_465_160])

        var data = ReferenceDataComponent()
        #expect(data.numgy == 1_960_634_880)
        #expect(data.rng.next() == 1_960_611_840)
    }

    @Test
    func populationMembershipMatchesFixturesForBothStorages() {
        let cases: [(count: Int, movement: Int, data: Int, players: Int)] = [
            (0, 0, 0, 0),
            (1, 0, 0, 1),
            (16, 12, 14, 1),
            (64, 49, 59, 1),
            (128, 128, 128, 64)
        ]

        for storage in Nexus.StorageKind.allCases {
            for fixture in cases {
                let uniform = Nexus(storage: storage)
                ReferenceUpdatePopulation.populate(nexus: uniform, entityCount: fixture.count, isMixed: false)
                #expect(uniform.numEntities == fixture.count)
                #expect(uniform.family(
                    requiresAll: ReferencePositionComponent.self,
                    ReferenceVelocityComponent.self
                ).count == fixture.count)
                #expect(uniform.family(requires: ReferenceDataComponent.self).count == fixture.count)
                #expect(uniform.family(requires: ReferencePlayerComponent.self).count == fixture.count)

                let mixed = Nexus(storage: storage)
                ReferenceUpdatePopulation.populate(nexus: mixed, entityCount: fixture.count, isMixed: true)
                #expect(mixed.numEntities == fixture.count)
                #expect(mixed.family(
                    requiresAll: ReferencePositionComponent.self,
                    ReferenceVelocityComponent.self
                ).count == fixture.movement)
                #expect(mixed.family(requires: ReferenceDataComponent.self).count == fixture.data)
                #expect(mixed.family(requires: ReferencePlayerComponent.self).count == fixture.players)
            }
        }
    }

    @Test
    func movementAndDataSystemsUpdateOnlyTheirQueryMembers() {
        let deltaTime: Float = 1.0 / 60.0

        for storage in Nexus.StorageKind.allCases {
            let nexus = Nexus(storage: storage)
            let moving = nexus.createEntity(
                with: ReferencePositionComponent(x: 2, y: 3),
                ReferenceVelocityComponent(x: 4, y: 6),
                ReferenceDataComponent()
            )
            let dataOnly = nexus.createEntity(
                with: ReferencePositionComponent(x: 7, y: 9),
                ReferenceDataComponent()
            )

            ReferenceMovementSystem(nexus: nexus).update(deltaTime: deltaTime)
            ReferenceDataSystem(nexus: nexus).update(deltaTime: deltaTime)

            let (movingPosition, movingData) = moving.get(
                components: ReferencePositionComponent.self,
                ReferenceDataComponent.self
            )
            let (stationaryPosition, stationaryData) = dataOnly.get(
                components: ReferencePositionComponent.self,
                ReferenceDataComponent.self
            )
            #expect(movingPosition?.x == 2 + 4 * deltaTime)
            #expect(movingPosition?.y == 3 + 6 * deltaTime)
            #expect(stationaryPosition?.x == 7)
            #expect(stationaryPosition?.y == 9)

            for data in [movingData, stationaryData] {
                #expect(data?.thingy == 1)
                #expect(data?.dingy == 0.0001 * Double(deltaTime))
                #expect(data?.mingy == true)
                #expect(data?.numgy == 1_960_611_840)
            }
        }
    }

    @Test
    func mixedSmallFixtureAddsForcedHeroAfterBaseRemovals() throws {
        let fixture = ReferenceUpdatePopulation.mixed(at: 0, entityCount: 1)
        let player = try #require(fixture.playerInitialization)

        #expect(fixture.removesPosition)
        #expect(fixture.removesVelocity)
        #expect(fixture.removesData)
        #expect(player.player.type == .hero)
        #expect(player.health.status == .spawn)
        #expect(player.sprite.character == 95)
    }

    @Test
    func repeatedUpdatesKeepFamiliesCurrentWhenComponentsAreRemovedAndRestored() throws {
        let deltaTime: Float = 1.0 / 60.0

        for storage in Nexus.StorageKind.allCases {
            let nexus = Nexus(storage: storage)
            ReferenceUpdatePopulation.populate(nexus: nexus, entityCount: 16, isMixed: true)
            var entityIterator = nexus.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self,
                ReferenceDataComponent.self
            ).entities.makeIterator()
            let possibleEntity = entityIterator.next()
            let entity = try #require(possibleEntity)
            let originalPosition = try #require(entity.get(ReferencePositionComponent.self))
            let velocity = try #require(entity.get(ReferenceVelocityComponent.self))
            let originalData = try #require(entity.get(ReferenceDataComponent.self))
            let movementFamily = nexus.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self
            )
            let dataFamily = nexus.family(requires: ReferenceDataComponent.self)
            let movement = ReferenceMovementSystem(nexus: nexus)
            let data = ReferenceDataSystem(nexus: nexus)
            let entityCount = nexus.numEntities
            let movementCount = movementFamily.count
            let dataCount = dataFamily.count

            #expect(entity.remove(ReferencePositionComponent.self))
            #expect(entity.remove(ReferenceDataComponent.self))
            movement.update(deltaTime: deltaTime)
            data.update(deltaTime: deltaTime)
            #expect(nexus.numEntities == entityCount)
            #expect(movementFamily.count == movementCount - 1)
            #expect(dataFamily.count == dataCount - 1)
            #expect(!entity.has(ReferencePositionComponent.self))
            #expect(!entity.has(ReferenceDataComponent.self))

            entity.set(originalPosition)
            entity.set(originalData)
            #expect(movementFamily.count == movementCount)
            #expect(dataFamily.count == dataCount)

            movement.update(deltaTime: deltaTime)
            data.update(deltaTime: deltaTime)
            let firstPosition = try #require(entity.get(ReferencePositionComponent.self))
            let firstData = try #require(entity.get(ReferenceDataComponent.self))
            #expect(firstPosition.x == originalPosition.x + velocity.x * deltaTime)
            #expect(firstPosition.y == originalPosition.y + velocity.y * deltaTime)
            #expect(firstData.thingy == originalData.thingy + 1)
            #expect(firstData.dingy == originalData.dingy + 0.0001 * Double(deltaTime))
            #expect(firstData.mingy == !originalData.mingy)

            var expectedRNG = originalData.rng
            let expectedNumgyAfterOne = expectedRNG.next()
            let expectedNumgyAfterTwo = expectedRNG.next()
            #expect(firstData.numgy == expectedNumgyAfterOne)

            movement.update(deltaTime: deltaTime)
            data.update(deltaTime: deltaTime)
            let secondPosition = try #require(entity.get(ReferencePositionComponent.self))
            let secondData = try #require(entity.get(ReferenceDataComponent.self))
            #expect(secondPosition.x == firstPosition.x + velocity.x * deltaTime)
            #expect(secondPosition.y == firstPosition.y + velocity.y * deltaTime)
            #expect(secondData.thingy == originalData.thingy + 2)
            #expect(secondData.dingy == firstData.dingy + 0.0001 * Double(deltaTime))
            #expect(secondData.mingy == originalData.mingy)
            #expect(secondData.numgy == expectedNumgyAfterTwo)
            #expect(nexus.numEntities == entityCount)
        }
    }
}
