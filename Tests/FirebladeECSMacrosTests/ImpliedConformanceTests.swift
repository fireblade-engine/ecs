//
//  ImpliedConformanceTests.swift
//  FirebladeECSMacrosTests
//

import FirebladeECSMacros
import Testing

/// Qualified lookup into the component before any conformance check (swiftlang/swift#92390).
struct ImpliedConformanceKindHolder {
    var kind: MacroImpliedConformance.Kind
}

@Suite struct ImpliedConformanceTests {
    let family: Family<MacroImpliedConformance>
    let nexus = Nexus()

    init() {
        family = nexus.family(requires: MacroImpliedConformance.self)
    }

    @Test func componentConformanceSurvivesEarlierMemberLookup() {
        let holder = ImpliedConformanceKindHolder(kind: .second)
        nexus.createEntity(with: MacroImpliedConformance())
        family.forEach(writing: MacroImpliedConformance.self) { $0.kind = holder.kind }
        #expect(family.count == 1)
        #expect(family.allSatisfy { $0.kind == .second })
    }
}
