//
//  FamilyTests2.swift
//  FirebladeECSTests
//
//  Created by Conductor on 2026-02-13.
//

import Testing
@testable import FirebladeECS

@Suite struct FamilyTests2 {

    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: Comp1(1), Comp2(2))
        
        #expect(family.count == 1)
        #expect(entity.numComponents == 2)
        #expect(entity.has(Comp1.self))
        #expect(entity.has(Comp2.self))
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        
        let count = 100
        for i in 0..<count {
            family.createMember(with: Comp1(i), Comp2(i * 2))
        }
        
        #expect(family.count == count)
        
        var i = 0
        family.forEach { (c1: Comp1, c2: Comp2) in
            #expect(c1.value == i)
            #expect(c2.value == i * 2)
            i += 1
        }
        #expect(i == count)
    }
}
