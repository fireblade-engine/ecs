import XCTest

import FirebladeECSPerformanceTests
import FirebladeECSTests

var tests = [XCTestCaseEntry]()
tests += FirebladeECSPerformanceTests.__allTests()
tests += FirebladeECSTests.__allTests()

XCTMain(tests)
