//
//  FamilyTests6.swift
//  FirebladeECSTests
//
//  Created by Conductor on 2026-02-13.
//

import Testing
@testable import FirebladeECS

@Suite struct FamilyTests6 {

    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: Comp1(1), Comp2(2), Comp3(3), Comp4(4), Comp5(5), Comp6(6))
        
        #expect(family.count == 1)
        #expect(entity.numComponents == 6)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        
        let count = 100
        for i in 0..<count {
            family.createMember(with: Comp1(i), Comp2(i * 2), Comp3(i * 3), Comp4(i * 4), Comp5(i * 5), Comp6(i * 6))
        }
        
        #expect(family.count == count)
        
        var i = 0
        family.forEach { (c1: Comp1, c2: Comp2, c3: Comp3, c4: Comp4, c5: Comp5, c6: Comp6) in
            #expect(c1.value == i)
            #expect(c2.value == i * 2)
            #expect(c3.value == i * 3)
            #expect(c4.value == i * 4)
            #expect(c5.value == i * 5)
            #expect(c6.value == i * 6)
            i += 1
        }
        #expect(i == count)
    }
}
