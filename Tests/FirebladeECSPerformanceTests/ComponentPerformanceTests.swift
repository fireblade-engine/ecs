//
//  ComponentIdentifierTests.swift
//  FirebladeECSPerformanceTests
//
//  Created by Christian Treffs on 14.02.19.
//

#if FRB_ENABLE_BENCHMARKS
import FirebladeECS
import XCTest

class ComponentIdentifierTests: XCTestCase {
    /// release: 0.034 sec
    /// debug:   0.456 sec
    func testMeasureStaticComponentIdentifier() {
        let number: Int = 1_000_000
        measure {
            for _ in 0..<number {
                let id = Position.identifier
                _ = id
            }
        }
    }

    /// release: 0.036 sec
    /// debug:   0.413 sec
    func testMeasureComponentIdentifier() {
        let number: Int = 1_000_000
        let pos = Position(x: 1, y: 2)
        measure {
            for _ in 0..<number {
                let id = pos.identifier
                _ = id
            }
        }
    }
}
#endif
