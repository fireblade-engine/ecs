//
//  SparseSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

@testable import FirebladeECS
import XCTest

class SparseSetTests: XCTestCase {
    var set: UnorderedSparseSet<Position, Int>!

    override func setUp() {
        super.setUp()
        set = UnorderedSparseSet<Position, Int>()
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
            XCTAssertEqual(set.storage.sparse[idx], idx)
            XCTAssertEqual(set.storage.dense.count, idx + 1)
        }

        XCTAssertEqual(set.count, num)
        XCTAssertEqual(set.storage.sparse.count, num)
        XCTAssertEqual(set.storage.dense.count, num)

        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, 2)
        XCTAssertEqual(set.get(at: 3)?.x, 3)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertTrue(set.contains(0))
        XCTAssertTrue(set.contains(1))
        XCTAssertTrue(set.contains(2))
        XCTAssertTrue(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertTrue(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], 0)
        XCTAssertEqual(set.storage.sparse[1], 1)
        XCTAssertEqual(set.storage.sparse[2], 2)
        XCTAssertEqual(set.storage.sparse[3], 3)
        XCTAssertEqual(set.storage.sparse[4], 4)
        XCTAssertEqual(set.storage.sparse[5], 5)
        XCTAssertEqual(set.storage.sparse[6], 6)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 3)

        XCTAssertEqual(set.count, num - 1)
        XCTAssertEqual(set.storage.sparse.count, num - 1)
        XCTAssertEqual(set.storage.dense.count, num - 1)

        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, 2)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertTrue(set.contains(0))
        XCTAssertTrue(set.contains(1))
        XCTAssertTrue(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertTrue(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], 0)
        XCTAssertEqual(set.storage.sparse[1], 1)
        XCTAssertEqual(set.storage.sparse[2], 2)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 4)
        XCTAssertEqual(set.storage.sparse[5], 5)
        XCTAssertEqual(set.storage.sparse[6], 3)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 2)

        XCTAssertEqual(set.count, num - 2)
        XCTAssertEqual(set.storage.sparse.count, num - 2)
        XCTAssertEqual(set.storage.dense.count, num - 2)

        XCTAssertEqual(set.get(at: 0)?.x, 0)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertTrue(set.contains(0))
        XCTAssertTrue(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertTrue(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], 0)
        XCTAssertEqual(set.storage.sparse[1], 1)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 4)
        XCTAssertEqual(set.storage.sparse[5], 2)
        XCTAssertEqual(set.storage.sparse[6], 3)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 0)

        XCTAssertEqual(set.count, num - 3)
        XCTAssertEqual(set.storage.sparse.count, num - 3)
        XCTAssertEqual(set.storage.dense.count, num - 3)

        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, 1)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertFalse(set.contains(0))
        XCTAssertTrue(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertTrue(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], nil)
        XCTAssertEqual(set.storage.sparse[1], 1)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 0)
        XCTAssertEqual(set.storage.sparse[5], 2)
        XCTAssertEqual(set.storage.sparse[6], 3)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 1)

        XCTAssertEqual(set.count, num - 4)
        XCTAssertEqual(set.storage.sparse.count, num - 4)
        XCTAssertEqual(set.storage.dense.count, num - 4)

        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, 6)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertFalse(set.contains(0))
        XCTAssertFalse(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertTrue(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], nil)
        XCTAssertEqual(set.storage.sparse[1], nil)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 0)
        XCTAssertEqual(set.storage.sparse[5], 2)
        XCTAssertEqual(set.storage.sparse[6], 1)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 6)

        XCTAssertEqual(set.count, num - 5)
        XCTAssertEqual(set.storage.sparse.count, num - 5)
        XCTAssertEqual(set.storage.dense.count, num - 5)

        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, 5)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertFalse(set.contains(0))
        XCTAssertFalse(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertTrue(set.contains(5))
        XCTAssertFalse(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], nil)
        XCTAssertEqual(set.storage.sparse[1], nil)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 0)
        XCTAssertEqual(set.storage.sparse[5], 1)
        XCTAssertEqual(set.storage.sparse[6], nil)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 5)

        XCTAssertEqual(set.count, num - 6)
        XCTAssertEqual(set.storage.sparse.count, num - 6)
        XCTAssertEqual(set.storage.dense.count, num - 6)

        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, 4)
        XCTAssertEqual(set.get(at: 5)?.x, nil)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertFalse(set.contains(0))
        XCTAssertFalse(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertTrue(set.contains(4))
        XCTAssertFalse(set.contains(5))
        XCTAssertFalse(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], nil)
        XCTAssertEqual(set.storage.sparse[1], nil)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], 0)
        XCTAssertEqual(set.storage.sparse[5], nil)
        XCTAssertEqual(set.storage.sparse[6], nil)
        XCTAssertEqual(set.storage.sparse[7], nil)

        // ---------------------------------------------
        set.remove(at: 4)

        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.storage.sparse.count, 0)
        XCTAssertEqual(set.storage.dense.count, 0)
        XCTAssertTrue(set.isEmpty)

        XCTAssertEqual(set.get(at: 0)?.x, nil)
        XCTAssertEqual(set.get(at: 1)?.x, nil)
        XCTAssertEqual(set.get(at: 2)?.x, nil)
        XCTAssertEqual(set.get(at: 3)?.x, nil)
        XCTAssertEqual(set.get(at: 4)?.x, nil)
        XCTAssertEqual(set.get(at: 5)?.x, nil)
        XCTAssertEqual(set.get(at: 6)?.x, nil)
        XCTAssertEqual(set.get(at: 7)?.x, nil)

        XCTAssertFalse(set.contains(0))
        XCTAssertFalse(set.contains(1))
        XCTAssertFalse(set.contains(2))
        XCTAssertFalse(set.contains(3))
        XCTAssertFalse(set.contains(4))
        XCTAssertFalse(set.contains(5))
        XCTAssertFalse(set.contains(6))
        XCTAssertFalse(set.contains(7))

        XCTAssertEqual(set.storage.sparse[0], nil)
        XCTAssertEqual(set.storage.sparse[1], nil)
        XCTAssertEqual(set.storage.sparse[2], nil)
        XCTAssertEqual(set.storage.sparse[3], nil)
        XCTAssertEqual(set.storage.sparse[4], nil)
        XCTAssertEqual(set.storage.sparse[5], nil)
        XCTAssertEqual(set.storage.sparse[6], nil)
        XCTAssertEqual(set.storage.sparse[7], nil)
    }

    func testSparseSetRemoveAndAdd() {
        testSparseSetRemove()

        let indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]

        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }

        XCTAssertEqual(set.count, indices.count)
        XCTAssertEqual(set.storage.sparse.count, indices.count)
        XCTAssertEqual(set.storage.dense.count, indices.count)
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
        let set = UnorderedSparseSet<AClass, Int>()
        let a = AClass()
        let b = AClass()
        set.insert(a, at: 0)
        set.insert(b, at: 1)

        XCTAssertEqual(set.storage.sparse.count, 2)
        XCTAssertEqual(set.storage.dense.count, 2)

        XCTAssertEqual(set.count, 2)

        XCTAssertTrue(set.get(at: 0) === a)
        XCTAssertTrue(set.get(at: 1) === b)

        XCTAssertEqual(set.count, 2)

        XCTAssertNotNil(set.remove(at: 1))

        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set.storage.sparse.count, 1)
        XCTAssertEqual(set.storage.dense.count, 1)

        XCTAssertNil(set.remove(at: 1))

        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set.storage.sparse.count, 1)
        XCTAssertEqual(set.storage.dense.count, 1)

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
            XCTAssertEqual(entry.x, idx)
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

        set.removeAll()

        XCTAssertEqual(set.count, 0)
        XCTAssertTrue(set.isEmpty)
    }

    func testSparseSetReduce() {
        let characters = UnorderedSparseSet<Character, Int>()

        characters.insert("H", at: 4)
        characters.insert("e", at: 13)
        characters.insert("l", at: 44)
        characters.insert("l", at: 123)
        characters.insert("o", at: 89)

        characters.insert(" ", at: 66)
        characters.insert("W", at: 77)
        characters.insert("o", at: 55)
        characters.insert("r", at: 90)
        characters.insert("l", at: 34)
        characters.insert("d", at: 140)

        XCTAssertEqual(characters.count, 11)

        let string: String = characters.storage.dense.reduce("") { res, char in
            res + "\(char.element)"
        }

        // NOTE: this tests only dense insertion order, this is no guarantee for the real ordering.
        XCTAssertEqual(string, "Hello World")
    }

    func testSubscript() {
        let characters = UnorderedSparseSet<Character, Int>()

        characters[4] = "H"
        characters[13] = "e"
        characters[44] = "l"
        characters[123] = "l"
        characters[89] = "o"

        characters[66] = " "
        characters[77] = "W"
        characters[55] = "o"
        characters[90] = "r"
        characters[34] = "l"
        characters[140] = "d"

        XCTAssertEqual(characters.count, 11)

        XCTAssertEqual(characters[4], "H")
        XCTAssertEqual(characters[13], "e")
        XCTAssertEqual(characters[44], "l")
        XCTAssertEqual(characters[123], "l")
        XCTAssertEqual(characters[89], "o")
        XCTAssertEqual(characters[66], " ")
        XCTAssertEqual(characters[77], "W")
        XCTAssertEqual(characters[55], "o")
        XCTAssertEqual(characters[90], "r")
        XCTAssertEqual(characters[34], "l")
        XCTAssertEqual(characters[140], "d")
    }

    func testStartEndIndex() {
        let set = UnorderedSparseSet<Character, Int>()

        set.insert("C", at: 33)
        set.insert("A", at: 11)
        set.insert("B", at: 22)

        let mapped = set.storage.dense.map { $0.element }

        XCTAssertEqual(mapped, ["C", "A", "B"])
    }

    func testAlternativeKey() {
        let set = UnorderedSparseSet<Character, String>()

        set.insert("A", at: "a")
        set.insert("C", at: "c")
        set.insert("B", at: "b")

        let mapped = set.storage.dense.map { $0.element }
        XCTAssertEqual(mapped, ["A", "C", "B"])
        let keyValues = set.storage.sparse.sorted(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
        for (a, b) in zip(keyValues, [("a", 0), ("c", 1), ("b", 2)]) {
            XCTAssertEqual(a.0, b.0)
            XCTAssertEqual(a.1, b.1)
        }
    }

    func testEquality() {
        let setA = UnorderedSparseSet<Int, String>()
        let setB = UnorderedSparseSet<Int, String>()

        setA.insert(3, at: "Hello")
        setB.insert(3, at: "Hello")

        XCTAssertEqual(setA, setB)

        setB.insert(4, at: "World")

        XCTAssertNotEqual(setA, setB)
    }
}
