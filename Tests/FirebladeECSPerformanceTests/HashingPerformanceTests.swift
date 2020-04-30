//
//  HashingPerformanceTests.swift
//  FirebladeECSPerformanceTests
//
//  Created by Christian Treffs on 14.02.19.
//

import FirebladeECS
import XCTest

class HashingPerformanceTests: XCTestCase {

    /// release:  0.726 sec
    /// debug:    3.179 sec
    func testMeasureCombineHash() {
        let a: Set<Int> = Set<Int>([14_561_291, 26_451_562, 34_562_182, 488_972_556, 5_128_426_962, 68_211_812])
        let b: Set<Int> = Set<Int>([1_083_838, 912_312, 83_333, 71_234_555, 4_343_234])
        let c: Set<Int> = Set<Int>([3_410_346_899_765, 90_000_002, 12_212_321, 71, 6_123_345_676_543])

        let input: ContiguousArray<Int> = ContiguousArray<Int>(arrayLiteral: a.hashValue, b.hashValue, c.hashValue)
        measure {
            for _ in 0..<1_000_000 {
                let hashRes: Int = FirebladeECS.hash(combine: input)
                _ = hashRes
            }
        }
    }

    /// release: 0.494 sec
    /// debug:   1.026 sec
    func testMeasureSetOfSetHash() {
        let a: Set<Int> = Set<Int>([14_561_291, 26_451_562, 34_562_182, 488_972_556, 5_128_426_962, 68_211_812])
        let b: Set<Int> = Set<Int>([1_083_838, 912_312, 83_333, 71_234_555, 4_343_234])
        let c: Set<Int> = Set<Int>([3_410_346_899_765, 90_000_002, 12_212_321, 71, 6_123_345_676_543])

        let input = Set<Set<Int>>(arrayLiteral: a, b, c)
        measure {
            for _ in 0..<1_000_000 {
                let hash: Int = input.hashValue
                _ = hash
            }
        }
    }

    /// release: 0.098 sec
    /// debug:  16.702 sec
    func testMeasureBernsteinDjb2() throws {
        #if !DEBUG
        let string = "The quick brown fox jumps over the lazy dog"
        measure {
            for _ in 0..<1_000_000 {
                let hash = StringHashing.bernstein_djb2(string)
                _ = hash
            }
        }
        #endif
    }

    /// release: 0.087 sec
    /// debug:   2.613 sec
    func testMeasureSingerDjb2() throws {
        let string = "The quick brown fox jumps over the lazy dog"
        measure {
            for _ in 0..<1_000_000 {
                let hash = StringHashing.singer_djb2(string)
                _ = hash
            }
        }
    }

    /// release: 0.088 sec
    /// debug:  30.766 sec
    func testMeasureSDBM() throws {
        #if !DEBUG
        let string = "The quick brown fox jumps over the lazy dog"
        measure {
            for _ in 0..<1_000_000 {
                let hash = StringHashing.sdbm(string)
                _ = hash
            }
        }
        #endif
    }

    /// release: 0.036 sec
    /// debug:   0.546 sec
    func testMeasureSwiftHasher() throws {
        #if !DEBUG
        let string = "The quick brown fox jumps over the lazy dog"
        measure {
            for _ in 0..<1_000_000 {
                var hasher = Hasher()
                hasher.combine(string)
                let hash = hasher.finalize()
                _ = hash
            }
        }
        #endif
    }

}
