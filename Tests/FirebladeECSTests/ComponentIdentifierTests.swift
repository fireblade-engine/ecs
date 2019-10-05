//
//  ComponentIdentifierTests.swift
//  
//
//  Created by Christian Treffs on 05.10.19.
//
import XCTest

final class ComponentIdentifierTests: XCTestCase {
    
    func testMirrorAsStableIdentifier() {
        let m = String(reflecting: Position.self)
        let identifier: String = m
        XCTAssertEqual(identifier, "FirebladeECSTests.Position")
    }
    
    func testStringDescribingAsStableIdentifier() {
        let s = String(describing: Position.self)
        let identifier: String = s
        XCTAssertEqual(identifier, "Position")
    }
}

