//
//  TypeIdentifierPerformanceTests.swift
//
//
//  Created by Christian Treffs on 05.10.19.
//

import FirebladeECS
import XCTest

final class TypeIdentifierPerformanceTests: XCTestCase {
    let maxIterations: Int = 100_000

    // release: 0.000 sec
    // debug:   0.051 sec
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

    /// release: 1.034 sec
    /// debug:
    func testPerformanceHash() {
        measure {
            for _ in 0..<maxIterations {
                _ = StringHashing.singer_djb2(String(describing: Color.self))
                _ = StringHashing.singer_djb2(String(describing: EmptyComponent.self))
                _ = StringHashing.singer_djb2(String(describing: Name.self))
                _ = StringHashing.singer_djb2(String(describing: Party.self))
                _ = StringHashing.singer_djb2(String(describing: Position.self))
                _ = StringHashing.singer_djb2(String(describing: SingleGameState.self))
                _ = StringHashing.singer_djb2(String(describing: Velocity.self))
            }
        }
    }

    /// release: 1.034 sec
    /// debug:   1.287 sec
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

    /// release: 1.187 sec
    /// debug:   1.498 sec
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

    /// release: 2.102 sec
    /// debug:   2.647 sec
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
