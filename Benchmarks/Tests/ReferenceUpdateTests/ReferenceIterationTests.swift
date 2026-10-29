import FirebladeECS
import Testing
@testable import ECSBenchmark

@Suite
struct ReferenceIterationTests {
    @Test
    func mixedPopulationMatchesReferenceFamilyCountsForBothStorages() {
        let cases: [(entityCount: Int, position: Int, positionVelocity: Int, allThree: Int)] = [
            (0, 0, 0, 0),
            (1, 0, 0, 0),
            (64, 54, 49, 45),
            (128, 127, 127, 127)
        ]

        for storage in Nexus.StorageKind.allCases {
            for fixture in cases {
                let nexus = Nexus(storage: storage)
                populateReferenceIterationPopulation(
                    nexus: nexus,
                    entityCount: fixture.entityCount,
                    workload: .mixedPositionVelocityData
                )

                #expect(nexus.numEntities == fixture.entityCount)
                #expect(nexus.family(requires: ReferencePositionComponent.self).count == fixture.position)
                #expect(nexus.family(
                    requiresAll: ReferencePositionComponent.self,
                    ReferenceVelocityComponent.self
                ).count == fixture.positionVelocity)
                #expect(nexus.family(
                    requiresAll: ReferencePositionComponent.self,
                    ReferenceVelocityComponent.self,
                    ReferenceDataComponent.self
                ).count == fixture.allThree)
            }
        }
    }

    @Test
    func mixedLargePopulationCountsEveryRemovalAndVelocityDataOverlap() {
        for storage in Nexus.StorageKind.allCases {
            let nexus = Nexus(storage: storage)
            populateReferenceIterationPopulation(
                nexus: nexus,
                entityCount: 512,
                workload: .mixedPositionVelocityData
            )

            #expect(nexus.numEntities == 512)
            #expect(nexus.numComponents == 1_532)
            #expect(nexus.family(requires: ReferencePositionComponent.self).count == 510)
            #expect(nexus.family(requires: ReferenceVelocityComponent.self).count == 511)
            #expect(nexus.family(requires: ReferenceDataComponent.self).count == 511)
            // Both losses hit the same selected index, so the combined family also loses only one entity.
            #expect(nexus.family(
                requiresAll: ReferenceVelocityComponent.self,
                ReferenceDataComponent.self
            ).count == 511)
            #expect(nexus.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self
            ).count == 509)
            #expect(nexus.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceDataComponent.self
            ).count == 509)
            #expect(nexus.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self,
                ReferenceDataComponent.self
            ).count == 509)
        }
    }

    @Test
    func typedIterationReadsExpectedComponentValuesForAllWorkloadsAndStorages() {
        for storage in Nexus.StorageKind.allCases {
            let positionOnly = Nexus(storage: storage)
            let expectedPositions: [[Int64]] = [[11, -11], [22, -22], [33, -33]]
            for expected in expectedPositions {
                positionOnly.createEntity(with: ReferencePositionComponent(x: Float(expected[0]), y: Float(expected[1])))
            }
            let positionFamily = positionOnly.family(requires: ReferencePositionComponent.self)
            var observedPositions: [[Int64]] = []
            positionFamily.forEach { (position: ReferencePositionComponent) in
                observedPositions.append([Int64(position.x), Int64(position.y)])
            }
            #expect(positionFamily.count == expectedPositions.count)
            #expect(observedPositions.sorted { $0.lexicographicallyPrecedes($1) } == expectedPositions.sorted { $0.lexicographicallyPrecedes($1) })

            let positionVelocity = Nexus(storage: storage)
            let expectedPositionVelocities: [[Int64]] = [[101, -101, 1, 2], [202, -202, 3, 4]]
            positionVelocity.createEntity(
                with: ReferencePositionComponent(x: 101, y: -101),
                ReferenceVelocityComponent(x: 1, y: 2)
            )
            positionVelocity.createEntity(
                with: ReferencePositionComponent(x: 202, y: -202),
                ReferenceVelocityComponent(x: 3, y: 4)
            )
            positionVelocity.createEntity(with: ReferencePositionComponent(x: 303, y: -303))
            let positionVelocityFamily = positionVelocity.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self
            )
            var observedPositionVelocities: [[Int64]] = []
            positionVelocityFamily.forEach {
                (position: ReferencePositionComponent, velocity: ReferenceVelocityComponent) in
                observedPositionVelocities.append([
                    Int64(position.x), Int64(position.y), Int64(velocity.x), Int64(velocity.y)
                ])
            }
            #expect(positionVelocityFamily.count == expectedPositionVelocities.count)
            #expect(observedPositionVelocities.sorted { $0.lexicographicallyPrecedes($1) } == expectedPositionVelocities.sorted { $0.lexicographicallyPrecedes($1) })

            let mixed = Nexus(storage: storage)
            let firstData = ReferenceDataComponent(seed: 111)
            let secondData = ReferenceDataComponent(seed: 222)
            let expectedMixed: [[Int64]] = [
                [1_001, -1_001, 11, 12, Int64(firstData.seed), Int64(firstData.numgy)],
                [2_002, -2_002, 21, 22, Int64(secondData.seed), Int64(secondData.numgy)]
            ]
            mixed.createEntity(
                with: ReferencePositionComponent(x: 1_001, y: -1_001),
                ReferenceVelocityComponent(x: 11, y: 12),
                firstData
            )
            mixed.createEntity(
                with: ReferencePositionComponent(x: 2_002, y: -2_002),
                ReferenceVelocityComponent(x: 21, y: 22),
                secondData
            )
            mixed.createEntity(
                with: ReferencePositionComponent(x: 3_003, y: -3_003),
                ReferenceVelocityComponent(x: 31, y: 32)
            )
            mixed.createEntity(
                with: ReferencePositionComponent(x: 4_004, y: -4_004),
                ReferenceDataComponent(seed: 444)
            )
            mixed.createEntity(with: ReferencePositionComponent(x: 5_005, y: -5_005))
            let mixedFamily = mixed.family(
                requiresAll: ReferencePositionComponent.self,
                ReferenceVelocityComponent.self,
                ReferenceDataComponent.self
            )
            var observedMixed: [[Int64]] = []
            mixedFamily.forEach {
                (position: ReferencePositionComponent, velocity: ReferenceVelocityComponent, data: ReferenceDataComponent) in
                observedMixed.append([
                    Int64(position.x), Int64(position.y), Int64(velocity.x), Int64(velocity.y),
                    Int64(data.seed), Int64(data.numgy)
                ])
            }
            #expect(mixedFamily.count == expectedMixed.count)
            #expect(observedMixed.sorted { $0.lexicographicallyPrecedes($1) } == expectedMixed.sorted { $0.lexicographicallyPrecedes($1) })
        }
    }

    @Test
    func benchmarkIterationOperationsRemainRunnableForEveryWorkloadAndStorage() {
        for storage in Nexus.StorageKind.allCases {
            for workload in ReferenceIterationWorkload.allCases {
                let nexus = Nexus(storage: storage)
                populateReferenceIterationPopulation(nexus: nexus, entityCount: 4, workload: workload)

                makeReferenceIterationOperation(nexus: nexus, workload: workload)()

                #expect(nexus.numEntities == 4)
            }
        }
    }
}
