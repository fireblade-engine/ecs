//
//  MemoryTests.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//
import XCTest
@testable import FirebladeECS

class MemoryTests: XCTestCase {

	func testCheckRetainCount() {

		class MyClass {}
		let myClass = MyClass()

		let initalCount: Int = FirebladeECS.retainCount(myClass)
		XCTAssert(initalCount == 3)

		let ownerdSelf: MyClass = myClass
		_ = ownerdSelf // creates strong reference
		let ownedOnceCount: Int = FirebladeECS.retainCount(myClass)
		XCTAssert(ownedOnceCount == initalCount + 1) // 4

		unowned let unownedSelf: MyClass = myClass
		_ = unownedSelf // creates unowned refrerence
		let unownedOnceCount: Int = FirebladeECS.retainCount(myClass)
		let unownedCount: Int = FirebladeECS.retainCount(unownedSelf)
		XCTAssert(ownedOnceCount == unownedCount)
		XCTAssert(ownedOnceCount == unownedOnceCount)

		weak var weakSelf: MyClass? = myClass
		_ = weakSelf // creates weak refrerence
		let weakOnceCount: Int = FirebladeECS.retainCount(myClass)
		let weakCount: Int = FirebladeECS.retainCount(weakSelf)
		XCTAssert(ownedOnceCount == weakCount)
		XCTAssert(ownedOnceCount == weakOnceCount)

	}

}
