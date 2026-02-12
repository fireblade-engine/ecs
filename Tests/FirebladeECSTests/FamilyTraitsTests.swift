//
//  FamilyTraitsTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 09.05.18.
//

import FirebladeECS
import Testing

@Suite struct FamilyTraitsTests {
    @Test func traitCommutativity() {
        let t1 = FamilyTraitSet(requiresAll: [Position.self, Velocity.self],
                                excludesAll: [Name.self])
        let t2 = FamilyTraitSet(requiresAll: [Velocity.self, Position.self],
                                excludesAll: [Name.self])

        #expect(t1 == t2)
        #expect(t1.hashValue == t2.hashValue)
    }

    @Test func traitMatching() {
        let nexus = Nexus()
        let a = nexus.createEntity()
        a.assign(Position(x: 1, y: 2))
        a.assign(Name(name: "myName"))
        a.assign(Velocity(a: 3.14))
        a.assign(EmptyComponent())

        let noMatch = nexus.family(requiresAll: Position.self, Velocity.self,
                                   excludesAll: Name.self)

        let isMatch = nexus.family(requiresAll: Position.self, Velocity.self)

        #expect(!noMatch.canBecomeMember(a))
        #expect(isMatch.canBecomeMember(a))
    }
}
