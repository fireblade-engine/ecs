import FirebladeECS
import Testing
@testable import ECSCompatBenchmark

private let updateCounts = [0, 1, 2, 3, 16, 17, 99, 100, 512]

/// Expected family sizes derived from the population fixtures, independent of the families themselves.
private struct ExpectedMembership {
    var created = 0
    var position = 0
    var velocity = 0
    var data = 0
    var positionVelocity = 0
    var positionVelocityData = 0
    var players = 0

    init(count: Int, isMixed: Bool) {
        created = count
        for index in 0 ..< count {
            let fixture = CompatPopulation.fixture(at: index, entityCount: count, isMixed: isMixed)
            let hasPlayer = fixture.playerInitialization != nil
            // Player initialization restores a removed Position.
            let hasPosition = !fixture.removesPosition || hasPlayer
            let hasVelocity = !fixture.removesVelocity
            let hasData = !fixture.removesData
            if hasPosition { position += 1 }
            if hasVelocity { velocity += 1 }
            if hasData { data += 1 }
            if hasPosition, hasVelocity { positionVelocity += 1 }
            if hasPosition, hasVelocity, hasData { positionVelocityData += 1 }
            if hasPlayer { players += 1 }
        }
    }
}

private func dataThingySum(_ nexus: Nexus) -> Int {
    nexus.family(requires: CompatData.self).reduce(0) { $0 + Int($1.payload.thingy) }
}

private func positionSum(_ nexus: Nexus) -> Double {
    nexus.family(requires: CompatPosition.self).reduce(0) { $0 + Double($1.payload.x) + Double($1.payload.y) }
}

@Suite
struct CompatUpdateTests {
    @Test
    func populationMatchesFixturesForBothPopulations() {
        for backend in CompatSuite.backends {
            for isMixed in [false, true] {
                for count in updateCounts {
                    let nexus = CompatSuite.makeNexus(backend: backend)
                    CompatPopulation.populate(nexus: nexus, entityCount: count, isMixed: isMixed)
                    let expected = ExpectedMembership(count: count, isMixed: isMixed)
                    #expect(nexus.numEntities == expected.created)
                    #expect(nexus.family(requires: CompatPosition.self).count == expected.position)
                    #expect(nexus.family(requires: CompatVelocity.self).count == expected.velocity)
                    #expect(nexus.family(requires: CompatData.self).count == expected.data)
                    #expect(nexus.family(requiresAll: CompatPosition.self, CompatVelocity.self).count == expected.positionVelocity)
                    #expect(nexus.family(requires: CompatPlayer.self).count == expected.players)
                    #expect(nexus.family(requires: CompatHealth.self).count == expected.players)
                    #expect(nexus.family(requires: CompatSprite.self).count == expected.players)
                    if !isMixed { #expect(expected.players == count) }
                }
            }
        }
    }

    @Test
    func basicUpdateVisitsAndChangesOnlyItsMembers() throws {
        for backend in CompatSuite.backends {
            for workload in [CompatWorkload.systemBasicUniform, .systemBasicMixed] {
                for count in updateCounts {
                    let isMixed = workload == .systemBasicMixed
                    let expected = ExpectedMembership(count: count, isMixed: isMixed)
                    let state = workload.prepare(backend: backend, count: count)
                    let world = try #require(state.runner as? CompatUpdateWorld)
                    let componentsBefore = state.nexus.numComponents
                    let thingyBefore = dataThingySum(state.nexus)
                    let positionBefore = positionSum(state.nexus)

                    let visits = world.update()

                    #expect(visits == [expected.positionVelocity, expected.data], "\(workload.identity) N=\(count)")
                    #expect(dataThingySum(state.nexus) == thingyBefore + expected.data)
                    // Velocity is (1, 1): each moved entity advances x and y by dt.
                    let moved = Double(expected.positionVelocity) * 2 * Double(CompatUpdateWorld.deltaTime)
                    #expect(abs(positionSum(state.nexus) - positionBefore - moved) < 0.01 * Double(max(count, 1)))
                    #expect(state.nexus.numComponents == componentsBefore)
                    #expect(state.nexus.numEntities == count)
                }
            }
        }
    }

    @Test
    func complexUpdateRunsSevenSystemsOverTheirFamilies() throws {
        for backend in CompatSuite.backends {
            for workload in [CompatWorkload.systemComplexUniform, .systemComplexMixed] {
                for count in updateCounts {
                    let expected = ExpectedMembership(count: count, isMixed: workload == .systemComplexMixed)
                    let state = workload.prepare(backend: backend, count: count)
                    let world = try #require(state.runner as? CompatUpdateWorld)
                    let visits = world.update()
                    #expect(visits == [
                        expected.positionVelocity, expected.data, expected.positionVelocityData,
                        expected.players, expected.players, expected.players, expected.position
                    ], "\(workload.identity) N=\(count)")
                }
            }
        }
    }

    @Test
    func complexUpdateDamagesHealthAndUpdatesSprites() throws {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.systemComplexUniform.prepare(backend: backend, count: 16)
            let world = try #require(state.runner as? CompatUpdateWorld)
            let before = Array(state.nexus.family(requiresAll: CompatHealth.self, CompatDamage.self)
                .map { Int($0.0.payload.hp) - Int($0.1.payload.atk) })
            _ = world.update()
            // Health is initialised at zero hp: the damage system lowers it by atk, the sprite system then marks it dead (66).
            let after = Array(state.nexus.family(requiresAll: CompatHealth.self, CompatSprite.self)
                .map { (Int($0.0.payload.hp), $0.1.payload.character) })
            #expect(after.count == 16)
            #expect(after.allSatisfy { $0.0 <= 0 && $0.1 == 66 })
            #expect(before.count == 16)
        }
    }

    @Test
    func updatesPersistAcrossPassesWithoutReset() throws {
        for backend in CompatSuite.backends {
            for workload in [CompatWorkload.systemBasicMixed, .systemComplexMixed] {
                let count = 100
                let expected = ExpectedMembership(count: count, isMixed: true)
                let state = workload.prepare(backend: backend, count: count)
                let start = dataThingySum(state.nexus)
                var operations: [Int] = []
                for pass in 1 ... 3 {
                    operations.append(workload.run(state, count: count).operations)
                    #expect(dataThingySum(state.nexus) == start + pass * expected.data, "\(workload.identity) pass \(pass)")
                }
                #expect(Set(operations).count == 1)
            }
        }
    }

    // MARK: - Events

    @Test
    func publishAddsThenClearsOneMarkerPerPositionVelocityMatch() throws {
        for backend in CompatSuite.backends {
            for count in updateCounts {
                let expected = ExpectedMembership(count: count, isMixed: true)
                let state = CompatWorkload.eventPublishMixed.prepare(backend: backend, count: count)
                let world = try #require(state.runner as? CompatEventWorld)
                let components = state.nexus.numComponents

                #expect(world.markerFamily.count == 0)
                #expect(world.publishMarkers() == expected.positionVelocity)
                #expect(world.markerFamily.count == expected.positionVelocity)
                #expect(world.visitEventView() == expected.positionVelocity)
                #expect(state.nexus.numComponents == components + expected.positionVelocity)
                #expect(world.clearMarkers() == expected.positionVelocity)
                #expect(world.markerFamily.count == 0)
                #expect(state.nexus.numComponents == components)
            }
        }
    }

    @Test
    func publishPassIsRepeatableOnTheSameWorld() throws {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.eventPublishMixed.prepare(backend: backend, count: 100)
            let expected = ExpectedMembership(count: 100, isMixed: true)
            let components = state.nexus.numComponents
            for _ in 0 ..< 3 {
                let outcome = CompatWorkload.eventPublishMixed.run(state, count: 100)
                #expect(outcome == CompatOutcome(operations: expected.positionVelocity * 2, hits: expected.positionVelocity, valueSum: 0))
                #expect(state.nexus.numComponents == components)
            }
        }
    }

    @Test
    func publishUpdateMovesEntitiesAndTouchesNoMarkers() throws {
        for backend in CompatSuite.backends {
            for count in updateCounts {
                let expected = ExpectedMembership(count: count, isMixed: true)
                let state = CompatWorkload.eventPublishUpdateMixed.prepare(backend: backend, count: count)
                let world = try #require(state.runner as? CompatEventWorld)
                let components = state.nexus.numComponents
                let positionBefore = positionSum(state.nexus)
                let outcome = CompatWorkload.eventPublishUpdateMixed.run(state, count: count)
                // Only the Position+Velocity update does work; the event view and the marker pool are empty.
                #expect(outcome == CompatOutcome(operations: expected.positionVelocity, hits: 0, valueSum: 0))
                #expect(world.eventView.count == 0)
                #expect(world.markerFamily.count == 0)
                #expect(state.nexus.numComponents == components)
                let moved = Double(expected.positionVelocity) * 2 * Double(CompatUpdateWorld.deltaTime)
                #expect(abs(positionSum(state.nexus) - positionBefore - moved) < 0.01 * Double(max(count, 1)))
            }
        }
    }

    // MARK: - Unsupported list

    @Test
    func unsupportedListIsUniqueAndDisjointFromSupportedIdentities() {
        let identities = CompatUnsupported.all.map(\.identity)
        #expect(Set(identities).count == identities.count)
        #expect(Set(identities).isDisjoint(with: CompatWorkload.allCases.map(\.identity)))
        #expect(CompatUnsupported.all.allSatisfy { !$0.reason.isEmpty && !$0.upstreamName.isEmpty })
        #expect(!identities.contains { $0.contains("bulk") && !$0.hasSuffix("-bulk") })
        #expect(identities.count == 10)
    }
}
