//
//  HashingPerformanceTests.swift
//  FirebladeECSPerformanceTests
//
//  Created by Christian Treffs on 14.02.19.
//

import XCTest
import FirebladeECS

class HashingPerformanceTests: XCTestCase {
    
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
    
    
}
