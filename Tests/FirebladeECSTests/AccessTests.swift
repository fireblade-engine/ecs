//
//  AccessTests.swift
//  
//
//  Created by Christian Treffs on 25.06.19.
//



import FirebladeECS
import XCTest

class AccessTests: XCTestCase {

    func testReadOnly() {
        let pos = Position(x: 1, y: 2)
        
        let readable = ReadableOnly<Position>(pos)
        
        XCTAssertEqual(readable.x, 1)
        XCTAssertEqual(readable.y, 2)
        
        // readable.x = 3 // does not work and that's correct!
    }
    
    func testWrite() {
        let pos = Position(x: 1, y: 2)
        
        let writable = Writable<Position>(pos)
        
        XCTAssertEqual(writable.x, 1)
        XCTAssertEqual(writable.y, 2)
        
        writable.x = 3
        
        XCTAssertEqual(writable.x, 3)
        XCTAssertEqual(pos.x, 3)

        XCTAssertEqual(writable.y, 2)
        XCTAssertEqual(pos.y, 2)

    }
}
