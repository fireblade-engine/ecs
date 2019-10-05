//
//  TypeIdentifierPerformanceTests.swift
//  
//
//  Created by Christian Treffs on 05.10.19.
//

import XCTest

final class TypeIdentifierPerformanceTests: XCTestCase {
    let maxIterations: Int = 100_000
    
    // 0.056 sec
    func testPerformanceObjectIdentifier() {
        measure {
            for _ in 0..<maxIterations {
                _ = ObjectIdentifier(Color.self)
                _ = ObjectIdentifier(EmptyComponent.self)
                _ = ObjectIdentifier(Name.self)
                _ = ObjectIdentifier(Party.self)
                _ = ObjectIdentifier(Position.self)
                _ = ObjectIdentifier(SingleGameState.self)
                _ = ObjectIdentifier(Velocity.self)
            }
        }
    }
    
    // 1.451 sec
    func testPerformanceStringDescribing() {
        measure {
            for _ in 0..<maxIterations {
                _ = String(describing: Color.self)
                _ = String(describing: EmptyComponent.self)
                _ = String(describing: Name.self)
                _ = String(describing: Party.self)
                _ = String(describing: Position.self)
                _ = String(describing: SingleGameState.self)
                _ = String(describing: Velocity.self)
            }
        }
    }
    
    // 1.587 sec
    func testPerformanceStringReflecting() {
        measure {
            for _ in 0..<maxIterations {
                _ = String(reflecting: Color.self)
                _ = String(reflecting: EmptyComponent.self)
                _ = String(reflecting: Name.self)
                _ = String(reflecting: Party.self)
                _ = String(reflecting: Position.self)
                _ = String(reflecting: SingleGameState.self)
                _ = String(reflecting: Velocity.self)
            }
        }
    }
    
    // 2.817 sec
    func testPerformanceMirrorReflectingDescription() {
        measure {
            for _ in 0..<maxIterations {
                _ = Mirror(reflecting: Color.self).description
                _ = Mirror(reflecting: EmptyComponent.self).description
                _ = Mirror(reflecting: Name.self).description
                _ = Mirror(reflecting: Party.self).description
                _ = Mirror(reflecting: Position.self).description
                _ = Mirror(reflecting: SingleGameState.self).description
                _ = Mirror(reflecting: Velocity.self).description
            }
        }
    }
    
}
