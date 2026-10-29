import FirebladeECS
import Testing
@testable import ECSCompatSuite

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

    /// `withPlayers: false` is the base-only mixed population of the event workloads.
    init(count: Int, isMixed: Bool, withPlayers: Bool = true) {
        created = count
        for index in 0 ..< count {
            let fixture = CompatPopulation.fixture(at: index, entityCount: count, isMixed: isMixed)
            let hasPlayer = withPlayers && fixture.playerInitialization != nil
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

    /// Hard-coded memberships of the mixed population, derived independently of `CompatPopulation` from the upstream recipe
    /// (BaseECSBenchmark.h `createEntitiesWithMixedComponents`, ECSBenchmark.h `BM_SystemsUpdateMixedEntities`).
    ///
    /// Base removals: entity i is eligible when N < 100 or 2N/4 <= i <= 3N/4 (integer division), and then only when its
    /// in-band ordinal j = i - 2N/4 is a multiple of 10 (any j when N < 100). Position/Velocity/Data are removed when
    /// i % 7 / 11 / 13 == 0.
    /// - N=99: every i is eligible. Position is removed for the 15 multiples of 7 (0...98), Velocity for the 9 multiples of 11,
    ///   Data for the 8 multiples of 13; 0 and 77 are multiples of both 7 and 11, so Position+Velocity survivors are
    ///   99 - (15 + 9 - 2) = 77, Data 99 - 8 = 91, all three 99 - 28 = 71 (inclusion-exclusion: 15 + 9 + 8 - (2 + 2 + 1) + 1 = 28).
    /// - N=100: band 50...75, ordinals 0, 10, 20 -> i = 50, 60, 70; only 70 is a multiple of 7 (none of 11 or 13).
    ///   Position+Velocity 99, Data 100, all three 99.
    /// - N=512: band 256...384, i = 256, 266, ..., 376 (13 entities); 266 and 336 lose Position, 286 loses Velocity and Data.
    ///   Position+Velocity 512 - 3 = 509, Data 511, all three 509.
    /// Players (mixed population only, ECSBenchmark.h): entity i is a candidate when N >= 100, or i == 0, or i >= N/8 with
    /// the running index j (incremented for every candidate including i == 0) even; a candidate becomes a player when i == 0
    /// or i is even (hero when i == 0 or i % 4 == 0, random when i % 6 == 0, otherwise monster). A player restores a removed
    /// Position, and never touches Velocity or Data.
    /// - N=99: N/8 = 12, so j is odd exactly on the even indices (12, 14, ...) and the gate only passes odd i: the only
    ///   player is i = 0. Position 84 + 1 restored = 85; Velocity, Data and Position+Velocity (i = 0 lacks Velocity) stay
    ///   90, 91, 77.
    /// - N=100: every even i is a player (50); Position is fully restored (70), so Position+Velocity 100, Data 100, all 100.
    /// - N=512: 256 even players; the Position removals 266 and 336 are restored, 286 still lacks Velocity and Data:
    ///   Position 512, Position+Velocity 511, Data 511, all three 511.
    private struct Expected {
        let count: Int
        let baseOnly: (positionVelocity: Int, data: Int, positionVelocityData: Int)
        let withPlayers: (players: Int, position: Int, positionVelocity: Int, data: Int, positionVelocityData: Int)
    }

    private static let hardCoded = [
        Expected(count: 99, baseOnly: (77, 91, 71), withPlayers: (1, 85, 77, 91, 71)),
        Expected(count: 100, baseOnly: (99, 100, 99), withPlayers: (50, 100, 100, 100, 100)),
        Expected(count: 512, baseOnly: (509, 511, 509), withPlayers: (256, 512, 511, 511, 511))
    ]

    @Test
    func mixedMembershipMatchesIndependentlyDerivedCounts() {
        for backend in CompatSuite.backends {
            for expected in Self.hardCoded {
                let withPlayers = CompatSuite.makeNexus(backend: backend)
                CompatPopulation.populate(nexus: withPlayers, entityCount: expected.count, isMixed: true)
                let counts = expected.withPlayers
                #expect(withPlayers.family(requires: CompatPlayer.self).count == counts.players, "N=\(expected.count)")
                #expect(withPlayers.family(requires: CompatPosition.self).count == counts.position, "N=\(expected.count)")
                #expect(withPlayers.family(requiresAll: CompatPosition.self, CompatVelocity.self).count == counts.positionVelocity, "N=\(expected.count)")
                #expect(withPlayers.family(requires: CompatData.self).count == counts.data, "N=\(expected.count)")
                #expect(withPlayers.family(requiresAll: CompatPosition.self, CompatVelocity.self, CompatData.self).count == counts.positionVelocityData, "N=\(expected.count)")

                let base = CompatSuite.makeNexus(backend: backend)
                CompatPopulation.populateBaseMixed(nexus: base, entityCount: expected.count)
                #expect(base.family(requires: CompatPlayer.self).count == 0)
                #expect(base.family(requiresAll: CompatPosition.self, CompatVelocity.self).count == expected.baseOnly.positionVelocity, "N=\(expected.count)")
                #expect(base.family(requires: CompatData.self).count == expected.baseOnly.data, "N=\(expected.count)")
                #expect(base.family(requiresAll: CompatPosition.self, CompatVelocity.self, CompatData.self).count == expected.baseOnly.positionVelocityData, "N=\(expected.count)")
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
                        expected.players, expected.players, expected.players, expected.players
                    ], "\(workload.identity) N=\(count)")
                }
            }
        }
    }

    @Test
    func healthDamageAndSpriteSystemsFollowTheUpstreamStateMachine() throws {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.systemComplexUniform.prepare(backend: backend, count: 16)
            let world = try #require(state.runner as? CompatUpdateWorld)
            let members = { Array(state.nexus.family(requiresAll: CompatHealth.self, CompatDamage.self, CompatSprite.self)
                .map { ($0.0.payload, $0.1.payload, $0.2.payload.character) }) }
            #expect(members().allSatisfy { $0.0.status == .spawn && $0.0.hp == 0 && $0.2 == 95 })

            // Pass 1: hp 0 and not dead -> Dead, damage skips (hp 0), sprite shows the grave.
            _ = world.update()
            #expect(members().count == 16)
            #expect(members().allSatisfy { $0.0.status == .dead && $0.0.hp == 0 && $0.2 == CompatSpriteSystem.grave })

            // Pass 2: Dead with hp 0 -> Spawn with max hp, then damage of atk - def (if positive), sprite shows spawn.
            _ = world.update()
            for (health, damage, character) in members() {
                let total = damage.atk - damage.def
                let expectedHP = total > 0 ? max(health.maxhp - total, 0) : health.maxhp
                #expect(health.status == .spawn)
                #expect(health.hp == expectedHP)
                #expect(character == CompatSpriteSystem.spawn)
            }
        }
    }

    @Test
    func moreComplexSystemRewritesVelocityOnEveryTenthThingy() throws {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.systemComplexUniform.prepare(backend: backend, count: 100)
            let world = try #require(state.runner as? CompatUpdateWorld)
            let velocities = { Array(state.nexus.family(requires: CompatVelocity.self).map { ($0.payload.x, $0.payload.y) }) }
            // The data system runs before the more-complex system, so thingy is 1...9 for nine passes: velocities stay (1, 1).
            for _ in 0 ..< 9 { _ = world.update() }
            #expect(velocities().allSatisfy { $0.0 == 1 && $0.1 == 1 })
            _ = world.update()
            #expect(velocities().contains { $0.0 != 1 || $0.1 != 1 })
        }
    }

    @Test
    func renderSystemDrawsInBoundsMembers() throws {
        for backend in CompatSuite.backends {
            let state = CompatWorkload.systemComplexUniform.prepare(backend: backend, count: 100)
            let world = try #require(state.runner as? CompatUpdateWorld)
            let render = try #require(world.render)
            _ = world.update()
            let inBounds = state.nexus.family(requiresAll: CompatPosition.self, CompatSprite.self)
                .filter { (0 ..< 320).contains(Int($0.0.payload.x)) && (0 ..< 240).contains(Int($0.0.payload.y)) }
                .count
            #expect(render.frameBuffer.drawn == inBounds)
            #expect(inBounds > 0)
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
                let expected = ExpectedMembership(count: count, isMixed: true, withPlayers: false)
                let state = CompatWorkload.eventPublishMixed.prepare(backend: backend, count: count)
                let world = try #require(state.runner as? CompatEventWorld)
                let components = state.nexus.numComponents

                #expect(world.markerFamily.count == 0)
                #expect(world.publishMarkers() == expected.positionVelocity)
                #expect(world.markerFamily.count == expected.positionVelocity)
                #expect(world.eventView == nil)
                #expect(state.nexus.family(requires: CompatPlayer.self).count == 0)
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
            let expected = ExpectedMembership(count: 100, isMixed: true, withPlayers: false)
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
                let expected = ExpectedMembership(count: count, isMixed: true, withPlayers: false)
                let state = CompatWorkload.eventPublishUpdateMixed.prepare(backend: backend, count: count)
                let world = try #require(state.runner as? CompatEventWorld)
                let components = state.nexus.numComponents
                let positionBefore = positionSum(state.nexus)
                let outcome = CompatWorkload.eventPublishUpdateMixed.run(state, count: count)
                // Only the Position+Velocity update does work; the event view and the marker pool are empty.
                #expect(outcome == CompatOutcome(operations: expected.positionVelocity, hits: 0, valueSum: 0))
                #expect(world.eventView?.count == 0)
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
