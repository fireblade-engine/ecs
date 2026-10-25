//
//  FamilyTraitsMacroIntegrationTests.swift
//  FirebladeECSMacrosTests
//
//  Created by Christian Treffs on 25.10.26.
//

import FirebladeECSMacros
import Testing

struct FTPosition: Component, Sendable { var x = 0 }
struct FTVelocity: Component, Sendable { var dx = 0 }
struct FTFrozen: Component, Sendable {}
struct FTA: Component, Sendable { var v = 1 }
struct FTB: Component, Sendable { var v = 2 }
struct FTC: Component, Sendable { var v = 3 }
struct FTD: Component, Sendable { var v = 4 }
struct FTE: Component, Sendable { var v = 5 }
public struct FTX: Component, Sendable { public var v = 0; public init() {} }
struct FTY: Component, Sendable { var v = 0 }

@FamilyTraits(reading: FTVelocity.self, writing: FTPosition.self, excluding: FTFrozen.self)
struct FTMovers {}

@FamilyTraits(reading: FTA.self, FTB.self, FTC.self, FTD.self, FTE.self)
struct FTManyReads {}

@FamilyTraits(writing: FTA.self, FTB.self, FTC.self, FTD.self, FTE.self)
struct FTManyWrites {}

@FamilyTraits(reading: FTA.self, FTB.self, FTC.self, FTD.self, FTE.self, writing: FTX.self, FTY.self)
struct FTWide {}

@FamilyTraits(writing: FTX.self)
public struct FTPublicWriter {}

@Suite struct FamilyTraitsMacroIntegrationTests {
    @Test func movesMembersAndSkipsExcluded() {
        let nexus = Nexus()
        let moving = nexus.createEntity(with: FTPosition(x: 1), FTVelocity(dx: 5))
        let frozen = nexus.createEntity(with: FTPosition(x: 1), FTVelocity(dx: 5), FTFrozen())
        let movers = FTMovers(in: nexus)
        movers.forEach { velocity, position in position.x += velocity.dx }
        #expect(moving.get(FTPosition.self)?.x == 6)
        #expect(frozen.get(FTPosition.self)?.x == 1)
        #expect(movers.count == 1)
        #expect(movers.isMember(moving))
        #expect(!movers.isMember(frozen))
    }

    @Test func staticSidesAreExposed() {
        #expect(FTMovers.traits == FamilyTraitSet(requiresAll: [FTVelocity.self, FTPosition.self], excludesAll: [FTFrozen.self]))
        #expect(FTMovers.readComponents == [FTVelocity.identifier])
        #expect(FTMovers.writeComponents == [FTPosition.identifier])
        #expect(FTMovers.familyIndex != FTManyReads.familyIndex)
        func describe<F: FamilyTraitsProviding>(_: F.Type) -> Int { F.traits.requiresAll.count }
        #expect(describe(FTWide.self) == 7)
    }

    @Test func bindsTheSameDeclarationToTwoNexuses() {
        let first = Nexus()
        let second = Nexus()
        first.createEntity(with: FTPosition(), FTVelocity())
        #expect(FTMovers(in: first).count == 1)
        #expect(FTMovers(in: second).isEmpty)
        #expect(FTMovers(in: first).family == first.family(requiresAll: FTVelocity.self, FTPosition.self, excludesAll: FTFrozen.self))
    }

    @Test func manyReadsUseThePackFallback() {
        let nexus = Nexus()
        nexus.createEntity(with: FTA(), FTB(), FTC(), FTD(), FTE())
        var sum = 0
        FTManyReads(in: nexus).forEach { a, b, c, d, e in sum += a.v + b.v + c.v + d.v + e.v }
        #expect(sum == 15)
    }

    @Test func manyWritesUseThePackFallback() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: FTA(), FTB(), FTC(), FTD(), FTE())
        FTManyWrites(in: nexus).forEach { a, b, c, d, e in
            a.v += 10
            e.v += 10
            _ = (b, c, d)
        }
        #expect(entity.get(FTA.self)?.v == 11)
        #expect(entity.get(FTE.self)?.v == 15)
    }

    @Test func wideFamilyReadsAndWrites() {
        let nexus = Nexus()
        let entity = nexus.createEntity(with: FTA(), FTB(), FTC(), FTD(), FTE(), FTX(), FTY())
        FTWide(in: nexus).forEach { a, b, c, d, e, x, y in
            x.v = a.v + b.v + c.v + d.v + e.v
            y.v = -x.v
        }
        #expect(entity.get(FTX.self)?.v == 15)
        #expect(entity.get(FTY.self)?.v == -15)
    }

    @Test func bodyErrorsPropagate() {
        struct Boom: Error {}
        let nexus = Nexus()
        nexus.createEntity(with: FTX())
        #expect(throws: Boom.self) {
            try FTPublicWriter(in: nexus).forEach { _ in throw Boom() }
        }
    }
}
