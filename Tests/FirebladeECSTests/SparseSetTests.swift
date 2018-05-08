//
//  SparseSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

@testable import FirebladeECS
import XCTest

class SparseSetTests: XCTestCase {
    
    func testSparseSetAdd() {
        let set = SparseSet<Position>()
        let num: Int = 100
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.add(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, num)
        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, 2)
        XCTAssertEqual(set.get(at: 3)?.x, 3)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, 7)
        XCTAssertEqual(set.get(at: 8)?.x, 8)
        XCTAssertEqual(set.get(at: 9)?.x, 9)
        XCTAssertEqual(set.get(at: 99)?.x, 99)
        XCTAssertEqual(set.get(at: 100)?.x, nil)
    }
    
    func testSparseSetAddNoReplace() {
        let set = SparseSet<Position>()
        let p1 = Position(x: 1, y: 1)
        let p2 = Position(x: 2, y: 2)
        
        set.add(p1, at: 10)
        
        XCTAssertEqual(set.get(at: 10)?.x, p1.x)
        XCTAssertEqual(set.count, 1)
        
        set.add(p2, at: 10)
        
        XCTAssertEqual(set.get(at: 10)?.x, p1.x)
        XCTAssertEqual(set.count, 1)
        
    }
    
    func testSparseSetRemove() {
        let set = SparseSet<Position>()
        let num: Int = 100
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.add(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, num)
        set.remove(at: 33)
        XCTAssertEqual(set.count, num-1)
        set.remove(at: 54)
        XCTAssertEqual(set.count, num-2)
        
        for idx in 0..<num {
            set.remove(at: idx)
        }
        
        XCTAssertEqual(set.count, 0)
    }
    
    func testSparseSetRemoveNonPresent() {
        let set = SparseSet<Position>()
        XCTAssertTrue(set.isEmpty)
        XCTAssertFalse(set.remove(at: 100))
        XCTAssertTrue(set.isEmpty)
    }
    
    func testSparseSetNonCongiuousData() {
        let set = SparseSet<Position>()
        
        var indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]
        
        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.add(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, indices.count)

        func recurseValueTest() {
            for idx in indices {
                XCTAssertEqual(set.get(at: idx)?.x, idx)
                XCTAssertEqual(set.get(at: idx)?.y, idx)
            }
        }

        recurseValueTest()
        
        while let idx = indices.popFirst() {
            set.remove(at: idx)
            recurseValueTest()
            XCTAssertEqual(set.count, indices.count)
        }
        
        XCTAssertEqual(set.count, indices.count)
        XCTAssertEqual(set.count, 0)
    }
    
    func testSparseSetClear() {
        let set = SparseSet<Position>()
        let num: Int = 100
        
        XCTAssertEqual(set.count, 0)
        XCTAssertTrue(set.isEmpty)
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.add(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, num)
        XCTAssertFalse(set.isEmpty)
        
        set.clear()
        
        XCTAssertEqual(set.count, 0)
        XCTAssertTrue(set.isEmpty)
    }
    
    func testSparseSetReduce() {
        let characters = SparseSet<Character>()
        
        
        characters.add("H", at: 4)
        characters.add("e", at: 13)
        characters.add("l", at: 34)
        characters.add("l", at: 44)
        characters.add("o", at: 55)
        characters.add(" ", at: 66)
        characters.add("W", at: 77)
        characters.add("o", at: 89)
        characters.add("r", at: 90)
        characters.add("l", at: 123)
        characters.add("d", at: 140)
        
        XCTAssertEqual(characters.count, 11)
        
        let string: String = characters.reduce("") { (res, char) in
            return res + "\(char)"
        }
        
        XCTAssertEqual(string, "Hello World")
        
    }
}
