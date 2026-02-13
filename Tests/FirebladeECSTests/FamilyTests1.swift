//
//  FamilyTests1.swift
//  FirebladeECSTests
//
//  Created by Conductor on 2026-02-13.
//

import Testing
import Foundation
@testable import FirebladeECS

@Suite struct FamilyTests1 {

    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: Comp1(1))
        
        #expect(family.count == 1)
        #expect(entity.numComponents == 1)
        #expect(entity.has(Comp1.self))
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self)
        #expect(family.isEmpty)
        
        let count = 100
        for i in 0..<count {
            family.createMember(with: Comp1(i))
        }
        
        #expect(family.count == count)
        
        var i = 0
        family.forEach { (c1: Comp1) in
            #expect(c1.value == i)
            i += 1
        }
        #expect(i == count)
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self)
        #expect(family.isEmpty)
        
        for i in 0..<10 {
            family.createMember(with: Comp1(i))
        }
        
        let strategy = DefaultCodingStrategy()
        let encoder = JSONEncoder()
        
        struct FamilyWrapper: Encodable {
            let components: (Comp1)
            let strategy: CodingStrategy
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: DynamicCodingKey.self)
                // Use Family.encode to encode components into this container
                try Family<Comp1>.encode(components: components, into: &container, using: strategy)
            }
        }
        
        let comp = Comp1(42)
        let wrapper = FamilyWrapper(components: (comp), strategy: strategy)
        let data = try encoder.encode(wrapper)
        
        #expect(data.count > 0)
    }
}

// Helper container for testing
struct FamilyMemberContainer<each C: Component> {
    let components: (repeat each C)
}
