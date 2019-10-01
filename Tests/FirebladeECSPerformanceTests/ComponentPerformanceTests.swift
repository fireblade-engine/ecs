//
//  ComponentPerformanceTests.swift
//  FirebladeECSPerformanceTests
//
//  Created by Christian Treffs on 14.02.19.
//

import FirebladeECS
import XCTest

class ComponentTests: XCTestCase {
    func testMeasureStaticComponentIdentifier() {
        let number: Int = 10_000
        measure {
            for _ in 0..<number {
                let id = Position.identifier
                _ = id
            }
        }
    }

    func testMeasureComponentIdentifier() {
        let number: Int = 10_000
        let pos = Position(x: 1, y: 2)
        measure {
            for _ in 0..<number {
                let id = pos.identifier
                _ = id
            }
        }
    }
}
