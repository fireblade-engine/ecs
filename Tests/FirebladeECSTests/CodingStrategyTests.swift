//
//  CodingStrategyTests.swift
//  FirebladeECSTests
//
//  Created by Conductor on 11.02.26.
//

import Testing
@testable import FirebladeECS

@Suite struct CodingStrategyTests {
    @Test func dynamicCodingKeyInit() {
        let intKey = DynamicCodingKey(intValue: 123)
        #expect(intKey?.intValue == 123)
        #expect(intKey?.stringValue == "123")

        let stringKey = DynamicCodingKey(stringValue: "hello")
        #expect(stringKey?.stringValue == "hello")
        #expect(stringKey?.intValue == nil)
    }
}
