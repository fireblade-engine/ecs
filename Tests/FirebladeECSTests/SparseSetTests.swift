//
//  SparseSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

@testable import FirebladeECS
import Testing

@Suite struct SparseSetTests {
    @Test func sparseSetAdd() {
        let set = UnorderedSparseSet<Position, Int>()
        let num: Int = 100

        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }

        #expect(set.count == num)
        #expect(set.get(at: 0)?.x == 0)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 2)?.x == 2)
        #expect(set.get(at: 3)?.x == 3)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == 7)
        #expect(set.get(at: 8)?.x == 8)
        #expect(set.get(at: 9)?.x == 9)
        #expect(set.get(at: 99)?.x == 99)
        #expect(set.get(at: 100)?.x == nil)
    }

    @Test func sparseSetAddAndReplace() {
        let set = UnorderedSparseSet<Position, Int>()
        let p1 = Position(x: 1, y: 1)
        let p2 = Position(x: 2, y: 2)

        #expect(set.insert(p1, at: 10))

        #expect(set.get(at: 10)?.x == p1.x)
        #expect(set.count == 1)

        #expect(!set.insert(p2, at: 10))

        #expect(set.get(at: 10)?.x == p2.x)
        #expect(set.count == 1)
    }

    @Test func sparseSetGet() {
        let set = UnorderedSparseSet<Position, Int>()
        let p1 = Position(x: 1, y: 1)

        set.insert(p1, at: 10)

        #expect(set.get(at: 10)?.x == p1.x)

        #expect(set.get(at: 33) == nil)

        #expect(set.remove(at: 10) != nil)

        #expect(set.get(at: 10) == nil)
    }

    @Test func sparseSetRemove() {
        let set = UnorderedSparseSet<Position, Int>()
        let num: Int = 7

        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
            #expect(set.storage.sparse[idx] == idx)
            #expect(set.storage.dense.count == idx + 1)
        }

        #expect(set.count == num)
        #expect(set.storage.sparse.count == num)
        #expect(set.storage.dense.count == num)

        #expect(set.get(at: 0)?.x == 0)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 2)?.x == 2)
        #expect(set.get(at: 3)?.x == 3)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == nil)

        #expect(set.contains(0))
        #expect(set.contains(1))
        #expect(set.contains(2))
        #expect(set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == 0)
        #expect(set.storage.sparse[1] == 1)
        #expect(set.storage.sparse[2] == 2)
        #expect(set.storage.sparse[3] == 3)
        #expect(set.storage.sparse[4] == 4)
        #expect(set.storage.sparse[5] == 5)
        #expect(set.storage.sparse[6] == 6)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 3)

        #expect(set.count == num - 1)
        #expect(set.storage.sparse.count == num - 1)
        #expect(set.storage.dense.count == num - 1)

        #expect(set.get(at: 0)?.x == 0)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 2)?.x == 2)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == nil)

        #expect(set.contains(0))
        #expect(set.contains(1))
        #expect(set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == 0)
        #expect(set.storage.sparse[1] == 1)
        #expect(set.storage.sparse[2] == 2)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 4)
        #expect(set.storage.sparse[5] == 5)
        #expect(set.storage.sparse[6] == 3)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 2)

        #expect(set.count == num - 2)
        #expect(set.storage.sparse.count == num - 2)
        #expect(set.storage.dense.count == num - 2)

        #expect(set.get(at: 0)?.x == 0)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == nil)

        #expect(set.contains(0))
        #expect(set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == 0)
        #expect(set.storage.sparse[1] == 1)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 4)
        #expect(set.storage.sparse[5] == 2)
        #expect(set.storage.sparse[6] == 3)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 0)

        #expect(set.count == num - 3)
        #expect(set.storage.sparse.count == num - 3)
        #expect(set.storage.dense.count == num - 3)

        #expect(set.get(at: 0)?.x == nil)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == nil)

        #expect(!set.contains(0))
        #expect(set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == nil)
        #expect(set.storage.sparse[1] == 1)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 0)
        #expect(set.storage.sparse[5] == 2)
        #expect(set.storage.sparse[6] == 3)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 1)

        #expect(set.count == num - 4)
        #expect(set.storage.sparse.count == num - 4)
        #expect(set.storage.dense.count == num - 4)

        #expect(set.get(at: 0)?.x == nil)
        #expect(set.get(at: 1)?.x == nil)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == 6)
        #expect(set.get(at: 7)?.x == nil)

        #expect(!set.contains(0))
        #expect(!set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == nil)
        #expect(set.storage.sparse[1] == nil)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 0)
        #expect(set.storage.sparse[5] == 2)
        #expect(set.storage.sparse[6] == 1)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 6)

        #expect(set.count == num - 5)
        #expect(set.storage.sparse.count == num - 5)
        #expect(set.storage.dense.count == num - 5)

        #expect(set.get(at: 0)?.x == nil)
        #expect(set.get(at: 1)?.x == nil)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == 5)
        #expect(set.get(at: 6)?.x == nil)
        #expect(set.get(at: 7)?.x == nil)

        #expect(!set.contains(0))
        #expect(!set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(set.contains(5))
        #expect(!set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == nil)
        #expect(set.storage.sparse[1] == nil)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 0)
        #expect(set.storage.sparse[5] == 1)
        #expect(set.storage.sparse[6] == nil)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 5)

        #expect(set.count == num - 6)
        #expect(set.storage.sparse.count == num - 6)
        #expect(set.storage.dense.count == num - 6)

        #expect(set.get(at: 0)?.x == nil)
        #expect(set.get(at: 1)?.x == nil)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == 4)
        #expect(set.get(at: 5)?.x == nil)
        #expect(set.get(at: 6)?.x == nil)
        #expect(set.get(at: 7)?.x == nil)

        #expect(!set.contains(0))
        #expect(!set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(set.contains(4))
        #expect(!set.contains(5))
        #expect(!set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == nil)
        #expect(set.storage.sparse[1] == nil)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == 0)
        #expect(set.storage.sparse[5] == nil)
        #expect(set.storage.sparse[6] == nil)
        #expect(set.storage.sparse[7] == nil)

        // ---------------------------------------------
        set.remove(at: 4)

        #expect(set.count == 0)
        #expect(set.storage.sparse.count == 0)
        #expect(set.storage.dense.count == 0)
        #expect(set.isEmpty)

        #expect(set.get(at: 0)?.x == nil)
        #expect(set.get(at: 1)?.x == nil)
        #expect(set.get(at: 2)?.x == nil)
        #expect(set.get(at: 3)?.x == nil)
        #expect(set.get(at: 4)?.x == nil)
        #expect(set.get(at: 5)?.x == nil)
        #expect(set.get(at: 6)?.x == nil)
        #expect(set.get(at: 7)?.x == nil)

        #expect(!set.contains(0))
        #expect(!set.contains(1))
        #expect(!set.contains(2))
        #expect(!set.contains(3))
        #expect(!set.contains(4))
        #expect(!set.contains(5))
        #expect(!set.contains(6))
        #expect(!set.contains(7))

        #expect(set.storage.sparse[0] == nil)
        #expect(set.storage.sparse[1] == nil)
        #expect(set.storage.sparse[2] == nil)
        #expect(set.storage.sparse[3] == nil)
        #expect(set.storage.sparse[4] == nil)
        #expect(set.storage.sparse[5] == nil)
        #expect(set.storage.sparse[6] == nil)
        #expect(set.storage.sparse[7] == nil)
    }

    @Test func sparseSetRemoveAndAdd() {
        let set = UnorderedSparseSet<Position, Int>()
        // setup
        let num: Int = 7
        for idx in 0..<num {
            set.insert(Position(x: idx, y: idx), at: idx)
        }
        for idx in 0..<num {
            set.remove(at: idx)
        }

        let indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]

        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }

        #expect(set.count == indices.count)
        #expect(set.storage.sparse.count == indices.count)
        #expect(set.storage.dense.count == indices.count)
        #expect(!set.isEmpty)

        #expect(set.get(at: 0)?.x == 0)
        #expect(set.get(at: 30)?.x == 30)
        #expect(set.get(at: 1)?.x == 1)
        #expect(set.get(at: 21)?.x == 21)
        #expect(set.get(at: 78)?.x == 78)
        #expect(set.get(at: 56)?.x == 56)
        #expect(set.get(at: 99)?.x == 99)
        #expect(set.get(at: 3)?.x == 3)
    }

    @Test func sparseSetRemoveNonPresent() {
        let set = UnorderedSparseSet<Position, Int>()
        #expect(set.isEmpty)
        #expect(set.remove(at: 100) == nil)
        #expect(set.isEmpty)
    }

    @Test func sparseSetDoubleRemove() {
        class AClass { }
        let set = UnorderedSparseSet<AClass, Int>()
        let a = AClass()
        let b = AClass()
        set.insert(a, at: 0)
        set.insert(b, at: 1)

        #expect(set.storage.sparse.count == 2)
        #expect(set.storage.dense.count == 2)

        #expect(set.count == 2)

        #expect(set.get(at: 0) === a)
        #expect(set.get(at: 1) === b)

        #expect(set.count == 2)

        #expect(set.remove(at: 1) != nil)

        #expect(set.count == 1)
        #expect(set.storage.sparse.count == 1)
        #expect(set.storage.dense.count == 1)

        #expect(set.remove(at: 1) == nil)

        #expect(set.count == 1)
        #expect(set.storage.sparse.count == 1)
        #expect(set.storage.dense.count == 1)

        #expect(set.get(at: 0) === a)

        #expect(set.count == 1)
    }

    @Test func sparseSetNonCongiuousData() {
        let set = UnorderedSparseSet<Position, Int>()
        var indices: Set<Int> = [0, 30, 1, 21, 78, 56, 99, 3]

        for idx in indices {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }

        #expect(set.count == indices.count)

        func recurseValueTest() {
            for idx in indices {
                #expect(set.get(at: idx)?.x == idx)
                #expect(set.get(at: idx)?.y == idx)
            }
        }

        recurseValueTest()

        while let idx = indices.popFirst() {
            let entry = set.remove(at: idx)!
            #expect(entry.x == idx)
            recurseValueTest()
            #expect(set.count == indices.count)
        }

        #expect(set.count == indices.count)
        #expect(set.count == 0)
    }

    @Test func sparseSetClear() {
        let set = UnorderedSparseSet<Position, Int>()
        let num: Int = 100

        #expect(set.count == 0)
        #expect(set.isEmpty)

        for idx in 0..<num {
            let pos = Position(x: idx, y: idx)
            set.insert(pos, at: idx)
        }

        #expect(set.count == num)
        #expect(!set.isEmpty)

        set.removeAll()

        #expect(set.count == 0)
        #expect(set.isEmpty)
    }

    @Test func sparseSetReduce() {
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

        #expect(characters.count == 11)

        let string: String = characters.storage.dense.reduce("") { res, char in
            res + "\(char.element)"
        }

        // NOTE: this tests only dense insertion order, this is no guarantee for the real ordering.
        #expect(string == "Hello World")
    }

    @Test func `subscript`() {
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

        #expect(characters.count == 11)

        #expect(characters[4] == "H")
        #expect(characters[13] == "e")
        #expect(characters[44] == "l")
        #expect(characters[123] == "l")
        #expect(characters[89] == "o")
        #expect(characters[66] == " ")
        #expect(characters[77] == "W")
        #expect(characters[55] == "o")
        #expect(characters[90] == "r")
        #expect(characters[34] == "l")
        #expect(characters[140] == "d")
    }

    @Test func startEndIndex() {
        let set = UnorderedSparseSet<Character, Int>()

        set.insert("C", at: 33)
        set.insert("A", at: 11)
        set.insert("B", at: 22)

        let mapped = set.storage.dense.map { $0.element }

        #expect(mapped == ["C", "A", "B"])
    }

    @Test func alternativeKey() {
        let set = UnorderedSparseSet<Character, String>()

        set.insert("A", at: "a")
        set.insert("C", at: "c")
        set.insert("B", at: "b")

        let mapped = set.storage.dense.map { $0.element }
        #expect(mapped == ["A", "C", "B"])
        let keyValues = set.storage.sparse.sorted(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
        for (a, b) in zip(keyValues, [("a", 0), ("c", 1), ("b", 2)]) {
            #expect(a.0 == b.0)
            #expect(a.1 == b.1)
        }
    }

    @Test func equality() {
        let setA = UnorderedSparseSet<Int, String>()
        let setB = UnorderedSparseSet<Int, String>()

        setA.insert(3, at: "Hello")
        setB.insert(3, at: "Hello")

        #expect(setA == setB)

        setB.insert(4, at: "World")

        #expect(setA != setB)
    }
}
