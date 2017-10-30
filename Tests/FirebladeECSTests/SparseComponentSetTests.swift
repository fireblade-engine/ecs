//
//  SparseComponentSetTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 31.10.17.
//

import XCTest
import FirebladeECS

class SparseComponentSetTests: XCTestCase {

	func testSet() {
		var s = SparseComponentSet<Position>()

		s.add(Position(x: 1, y: 2), with: 0)
		s.add(Position(x: 13, y: 23), with: 13)
		s.add(Position(x: 123, y: 123), with: 123)

		for p in s {
			print(p.x, p.y)
		}

		s.remove(13)

		for p in s {
			print(p.x, p.y)
		}

		s.remove(234567890)
	}
}
