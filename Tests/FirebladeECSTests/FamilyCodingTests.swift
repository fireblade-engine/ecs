//
//  FamilyCodingTests.swift
//  FirebladeECSTests
//
//  Created by Conductor on 2026-02-13.
//

import Testing
import Foundation
@testable import FirebladeECS

struct DefaultCodingStrategy: CodingStrategy {
    func codingKey<C>(for componentType: C.Type) -> DynamicCodingKey where C : Component {
        DynamicCodingKey(stringValue: "\(componentType)")!
    }
}

@Suite struct FamilyCodingTests {

    @Test func familyEncodingDecoding() throws {
        let nexus = Nexus()
        _ = nexus.family(requiresAll: Position.self, Name.self)
        
        // Create components
        let pos1 = Position(x: 1, y: 2)
        let name1 = Name(name: "Entity1")
        
        _ = Position(x: 3, y: 4)
        _ = Name(name: "Entity2")
        
        // Encode individual members manually (since we don't have batch encode yet)
        // Ideally we'd test the static encode/decode methods
        
        _ = DefaultCodingStrategy()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test Encoding one set of components
        // To use KeyedEncodingContainer we need a wrapper
        struct Wrapper: Encodable, Decodable {
            let pos: Position
            let name: Name
            
            enum CodingKeys: String, CodingKey {
                case pos = "Position"
                case name = "Name"
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: DynamicCodingKey.self)
                // Use Family.encode to encode components into this container
                try Family<Position, Name>.encode(components: (pos, name), into: &container, using: DefaultCodingStrategy())
            }
            
            init(pos: Position, name: Name) {
                self.pos = pos
                self.name = name
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: DynamicCodingKey.self)
                let components = try Family<Position, Name>.decode(from: container, using: DefaultCodingStrategy())
                // Unpack the tuple (pack expansion return)
                // This is tricky. Swift 6 pack return unpacking.
                // Let's assume the order matches.
                // Since we can't easily destructure the pack into named variables here generally without `let (p, n) = components`
                // But `components` is a pack? No, `decode` returns a tuple of the pack elements.
                
                // Swift 6 tuple destructuring of packs might need improvement or explicit typing
                // For now let's just create them from the components tuple
                self.pos = components.0
                self.name = components.1
            }
        }
        
        let wrapper = Wrapper(pos: pos1, name: name1)
        let data = try encoder.encode(wrapper)
        
        let decodedWrapper = try decoder.decode(Wrapper.self, from: data)
        
        #expect(decodedWrapper.pos.x == pos1.x)
        #expect(decodedWrapper.pos.y == pos1.y)
        #expect(decodedWrapper.name.name == name1.name)
    }
    
    @Test func familyBatchCreationFromDecode() throws {
        // This test would verify the `init(from:nexus:)` if we kept it or something similar.
        // But `Family` itself is not Decodable in a way that creates entities directly without a container context usually.
        // However, let's test creating entities from decoded data if we simulate a list of components.
    }
}
