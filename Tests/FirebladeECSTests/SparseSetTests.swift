//
//  SparseSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

@testable import FirebladeECS
import XCTest

class SparseSetTests: XCTestCase {

	func testSparseComponentSet() {
		let s = SparseComponentSet()

		let num: Int = 100

		for i in 0..<num {
			s.add(Position(x: i, y: i), at: EntityIndex(i))
		}

		XCTAssert(s.count == num)

		for i in 0..<num {
			let idx = num - i - 1
			let p: Position = s.get(at: idx) as! Position
			XCTAssertEqual(idx, p.x)
		}

		for i in 0..<num {
			s.remove(at: EntityIndex(i))
		}

		XCTAssert(s.count == 0)
	}
}
