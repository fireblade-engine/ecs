//
//  FamilyTraitsProvidingTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

private struct Frozen: Component, Sendable {}

/// A hand-written conformance, the macro writes the same.
private struct Movers: FamilyTraitsProviding {
    static let traits = FamilyTraitSet(requiresAll: [Comp1.self, Comp2.self], excludesAll: [Frozen.self])
    static let readComponents: Set<ComponentIdentifier> = [Comp1.identifier]
    static let writeComponents: Set<ComponentIdentifier> = [Comp2.identifier]
    static let familyIndex = Nexus.FamilyIndexRegistry.shared.index(of: Movers.self)

    let family: Family<Comp1, Comp2>

    static func makeFamily(in nexus: Nexus) -> Family<Comp1, Comp2> {
        nexus.family(requiresAll: Comp1.self, Comp2.self, excludesAll: Frozen.self)
    }

    init(in nexus: Nexus) {
        family = nexus.family(for: Movers.self)
    }
}

/// Relies on all defaults, including the lazily assigned index.
private struct Plain: FamilyTraitsProviding {
    static let traits = FamilyTraitSet(requiresAll: [Comp3.self], excludesAll: [])
    let family: Family<Comp3>

    static func makeFamily(in nexus: Nexus) -> Family<Comp3> {
        nexus.family(requires: Comp3.self)
    }

    init(in nexus: Nexus) {
        family = nexus.family(for: Plain.self)
    }
}

@Suite struct FamilyTraitsProvidingTests {
    @Test func boundFamilyTracksMembership() {
        let nexus = Nexus()
        let movers = Movers(in: nexus)
        #expect(movers.isEmpty)
        let entity = nexus.createEntity(with: Comp1(1), Comp2(2))
        #expect(movers.count == 1)
        #expect(movers.isMember(entity))
        #expect(Array(movers.entities) == [entity])
        entity.set(Frozen())
        #expect(movers.isEmpty)
        #expect(!movers.isMember(entity))
    }

    @Test func familyIsCachedPerNexus() {
        let nexus = Nexus()
        _ = Movers(in: nexus)
        let families = nexus.numFamilies
        _ = Movers(in: nexus)
        _ = nexus.family(for: Movers.self)
        #expect(nexus.numFamilies == families)
        #expect(Movers(in: nexus).family == nexus.family(requiresAll: Comp1.self, Comp2.self, excludesAll: Frozen.self))
    }

    @Test func sameDeclarationBindsToAnotherNexus() {
        let first = Nexus()
        let second = Nexus()
        first.createEntity(with: Comp1(1), Comp2(2))
        #expect(Movers(in: first).count == 1)
        #expect(Movers(in: second).count == 0)
        second.createEntity(with: Comp1(1), Comp2(2))
        second.createEntity(with: Comp1(1), Comp2(2))
        #expect(Movers(in: second).count == 2)
        #expect(Movers(in: first).count == 1)
    }

    @Test func familyIndicesAreDenseAndDistinct() {
        #expect(Movers.familyIndex != Plain.familyIndex)
        #expect(Plain.familyIndex == Plain.familyIndex)
    }

    @Test func accessSetsAreStatic() {
        #expect(Movers.readComponents == [Comp1.identifier])
        #expect(Movers.writeComponents == [Comp2.identifier])
        #expect(Plain.readComponents == [Comp3.identifier])
        #expect(Plain.writeComponents.isEmpty)
    }

    @Test func genericOverTheProtocol() {
        func traits<F: FamilyTraitsProviding>(_: F.Type) -> FamilyTraitSet { F.traits }
        #expect(traits(Movers.self) == nexusTraits)
    }

    @Test func clearRebindsTheFamily() {
        let nexus = Nexus()
        _ = Movers(in: nexus)
        nexus.createEntity(with: Comp1(1), Comp2(2))
        nexus.clear()
        #expect(nexus.boundFamilies.isEmpty)
        nexus.createEntity(with: Comp1(1), Comp2(2))
        #expect(Movers(in: nexus).count == 1)
    }

    @Test func plainConformanceUsesLazyIndex() {
        let nexus = Nexus()
        nexus.createEntity(with: Comp3(3))
        #expect(Plain(in: nexus).count == 1)
    }

    private var nexusTraits: FamilyTraitSet { Movers.traits }
}
