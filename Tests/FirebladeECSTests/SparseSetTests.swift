//
//  SparseSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

@testable import FirebladeECS
import XCTest

class SparseSetTests: XCTestCase {
    
    var set: UnorderedSparseSet<Position>!
    
    override func setUp() {
        super.setUp()
        set = UnorderedSparseSet<Position>()
    }
    
    override func tearDown() {
        set = nil
        super.tearDown()
    }
    
    func testSparseSetAdd() {
        
        let num: Int = 100
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
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
    
    func testSparseSetAddAndReplace() {
        
        let p1 = Position(x: 1, y: 1)
        let p2 = Position(x: 2, y: 2)
        
        XCTAssertTrue(set.insert(p1, at: 10))
        
        XCTAssertEqual(set.get(at: 10)?.x, p1.x)
        XCTAssertEqual(set.count, 1)
        
        XCTAssertFalse(set.insert(p2, at: 10))
        
        XCTAssertEqual(set.get(at: 10)?.x, p2.x)
        XCTAssertEqual(set.count, 1)
        
    }
    
    func testSparseSetGet() {
        
        let p1 = Position(x: 1, y: 1)
        
        set.insert(p1, at: 10)
        
        XCTAssertEqual(set.get(at: 10)?.x, p1.x)
        
        XCTAssertNil(set.get(at: 33))
        
        XCTAssertNotNil(set.remove(at: 10))
        
        XCTAssertNil(set.get(at: 10))
    }
    
    func testSparseSetRemove() {
        
        let num: Int = 7
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
            XCTAssertEqual(set.sparse[idx], idx)
            XCTAssertEqual(set.dense.count, idx+1)
        }
        
        XCTAssertEqual(set.count, num)
        XCTAssertEqual(set.sparse.count, num)
        XCTAssertEqual(set.dense.count, num)
        
        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, 2)
        XCTAssertEqual(set.get(at: 3)?.x, 3)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], 0)
        XCTAssertEqual(set.sparse[1], 1)
        XCTAssertEqual(set.sparse[2], 2)
        XCTAssertEqual(set.sparse[3], 3)
        XCTAssertEqual(set.sparse[4], 4)
        XCTAssertEqual(set.sparse[5], 5)
        XCTAssertEqual(set.sparse[6], 6)
        XCTAssertEqual(set.sparse[7], nil)
        
        
        // ---------------------------------------------
        set.remove(at: 3)
        
        XCTAssertEqual(set.count, num-1)
        XCTAssertEqual(set.sparse.count, num-1)
        XCTAssertEqual(set.dense.count, num-1)
        
        
        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, 2)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], 0)
        XCTAssertEqual(set.sparse[1], 1)
        XCTAssertEqual(set.sparse[2], 2)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 4)
        XCTAssertEqual(set.sparse[5], 5)
        XCTAssertEqual(set.sparse[6], 3)
        XCTAssertEqual(set.sparse[7], nil)
        
        
        
        // ---------------------------------------------
        set.remove(at: 2)
        
        XCTAssertEqual(set.count, num-2)
        XCTAssertEqual(set.sparse.count, num-2)
        XCTAssertEqual(set.dense.count, num-2)
        
        
        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], 0)
        XCTAssertEqual(set.sparse[1], 1)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 4)
        XCTAssertEqual(set.sparse[5], 2)
        XCTAssertEqual(set.sparse[6], 3)
        XCTAssertEqual(set.sparse[7], nil)
        
        
        
        // ---------------------------------------------
        set.remove(at: 0)
        
        XCTAssertEqual(set.count, num-3)
        XCTAssertEqual(set.sparse.count, num-3)
        XCTAssertEqual(set.dense.count, num-3)
        
        
        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], nil)
        XCTAssertEqual(set.sparse[1], 1)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 0)
        XCTAssertEqual(set.sparse[5], 2)
        XCTAssertEqual(set.sparse[6], 3)
        XCTAssertEqual(set.sparse[7], nil)
        
        
        
        // ---------------------------------------------
        set.remove(at: 1)
        
        XCTAssertEqual(set.count, num-4)
        XCTAssertEqual(set.sparse.count, num-4)
        XCTAssertEqual(set.dense.count, num-4)
        
        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], nil)
        XCTAssertEqual(set.sparse[1], nil)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 0)
        XCTAssertEqual(set.sparse[5], 2)
        XCTAssertEqual(set.sparse[6], 1)
        XCTAssertEqual(set.sparse[7], nil)
        
        // ---------------------------------------------
        set.remove(at: 6)
        
        XCTAssertEqual(set.count, num-5)
        XCTAssertEqual(set.sparse.count, num-5)
        XCTAssertEqual(set.dense.count, num-5)
        
        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], nil)
        XCTAssertEqual(set.sparse[1], nil)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 0)
        XCTAssertEqual(set.sparse[5], 1)
        XCTAssertEqual(set.sparse[6], nil)
        XCTAssertEqual(set.sparse[7], nil)
        
        // ---------------------------------------------
        set.remove(at: 5)
        
        XCTAssertEqual(set.count, num-6)
        XCTAssertEqual(set.sparse.count, num-6)
        XCTAssertEqual(set.dense.count, num-6)
        
        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, nil)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], nil)
        XCTAssertEqual(set.sparse[1], nil)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], 0)
        XCTAssertEqual(set.sparse[5], nil)
        XCTAssertEqual(set.sparse[6], nil)
        XCTAssertEqual(set.sparse[7], nil)
        
        // ---------------------------------------------
        set.remove(at: 4)
        
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.sparse.count, 0)
        XCTAssertEqual(set.dense.count, 0)
        XCTAssertTrue(set.isEmpty)
        
        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, nil)
        XCTAssertEqual(set.get(at: 5)?.x, nil)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)
        
        XCTAssertEqual(set.sparse[0], nil)
        XCTAssertEqual(set.sparse[1], nil)
        XCTAssertEqual(set.sparse[2], nil)
        XCTAssertEqual(set.sparse[3], nil)
        XCTAssertEqual(set.sparse[4], nil)
        XCTAssertEqual(set.sparse[5], nil)
        XCTAssertEqual(set.sparse[6], nil)
        XCTAssertEqual(set.sparse[7], nil)
        
    }
    
    func testSparseSetRemoveAndAdd() {
        testSparseSetRemove()
        
        let indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]
        
        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, indices.count)
        XCTAssertEqual(set.sparse.count, indices.count)
        XCTAssertEqual(set.dense.count, indices.count)
        XCTAssertFalse(set.isEmpty)
        
        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 30)?.x, 30)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 21)?.x, 21)
        XCTAssertEqual(set.get(at: 78)?.x, 78)
        XCTAssertEqual(set.get(at: 56)?.x, 56)
        XCTAssertEqual(set.get(at: 99)?.x, 99)
        XCTAssertEqual(set.get(at: 3)?.x, 3)
        
        
    }
    
    func testSparseSetRemoveNonPresent() {
        
        XCTAssertTrue(set.isEmpty)
        XCTAssertNil(set.remove(at: 100))
        XCTAssertTrue(set.isEmpty)
    }
    
    func testSparseSetDoubleRemove() {
        class AClass { }
        let set = UnorderedSparseSet<AClass>()
        let a = AClass()
        let b = AClass()
        set.insert(a, at: 0)
        set.insert(b, at: 1)
        
        XCTAssertEqual(set.sparse.count, 2)
        XCTAssertEqual(set.dense.count, 2)
        
        XCTAssertEqual(set.count, 2)
        
        XCTAssertTrue(set.get(at: 0) === a)
        XCTAssertTrue(set.get(at: 1) === b)
        
        XCTAssertEqual(set.count, 2)
        
        XCTAssertNotNil(set.remove(at: 1))
        
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set.sparse.count, 1)
        XCTAssertEqual(set.dense.count, 1)
        
        
        XCTAssertNil(set.remove(at: 1))
        
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set.sparse.count, 1)
        XCTAssertEqual(set.dense.count, 1)
        
        
        XCTAssertTrue(set.get(at: 0) === a)
        
        XCTAssertEqual(set.count, 1)
        
    }
    
    func testSparseSetNonCongiuousData() {
        
        
        var indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]
        
        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
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
            let entry = set.remove(at: idx)!
            XCTAssertEqual(entry.key, idx)
            recurseValueTest()
            XCTAssertEqual(set.count, indices.count)
        }
        
        XCTAssertEqual(set.count, indices.count)
        XCTAssertEqual(set.count, 0)
    }
    
    func testSparseSetClear() {
        
        let num: Int = 100
        
        XCTAssertEqual(set.count, 0)
        XCTAssertTrue(set.isEmpty)
        
        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }
        
        XCTAssertEqual(set.count, num)
        XCTAssertFalse(set.isEmpty)
        
        set.clear()
        
        XCTAssertEqual(set.count, 0)
        XCTAssertTrue(set.isEmpty)
    }
    
    func testSparseSetReduce() {
        let characters = UnorderedSparseSet<Character>()
        
        
        characters.insert("H", at: 4)
        characters.insert("e", at: 13)
        
        characters.insert("l", at: 44)
        characters.insert("o", at: 89)
        
        characters.insert(" ", at: 66)
        characters.insert("d", at: 140)
        characters.insert("W", at: 77)
        
        characters.insert("r", at: 90)
        characters.insert("l", at: 123)
        characters.insert("o", at: 55)
        characters.insert("l", at: 34)
        
        
        XCTAssertEqual(characters.count, 11)
        
        let string: String = characters.reduce("") { (res, char) in
            return res + "\(char)"
        }
        
        XCTAssertEqual(string, "Hello World")
        
    }
}
