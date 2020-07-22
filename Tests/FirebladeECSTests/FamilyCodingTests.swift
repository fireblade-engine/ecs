//
//  FamilyCodingTests.swift
//
//
//  Created by Christian Treffs on 22.07.20.
//

import FirebladeECS
import XCTest

final class FamilyCodingTests: XCTestCase {

    func testEncodingFamily1() throws {
        let nexus = Nexus()

        let family = nexus.family(requires: MyComponent.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true))
        family.createMember(with: MyComponent(name: "Your Name", flag: false))
        XCTAssertEqual(family.count, 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThanOrEqual(encodedData.count, 90)
    }

    func testDecodingFamily1() throws {
        let jsonString = """
         [
           {
             "MyComponent": {
               "name": "My Name",
               "flag": true
             }
           },
           {
             "MyComponent": {
               "name": "Your Name",
               "flag": false
             }
           }
         ]
        """
        let jsonData = jsonString.data(using: .utf8)!

        let nexus = Nexus()
        let family = nexus.family(requires: MyComponent.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        try family.decodeMembers(from: jsonData, using: &jsonDecoder)

        XCTAssertEqual(family.count, 2)

    }

    func testEncodeFamily2() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        family.createMember(with: (MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23)))
        family.createMember(with: (MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45)))
        XCTAssertEqual(family.count, 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThanOrEqual(encodedData.count, 91)
    }

    func testDecodingFamily2() throws {
        let jsonString = """
        [
          {
            "MyComponent": {
              "name": "My Name",
              "flag": true
            },
            "YourComponent": {
              "number": 2.13
            }
          },
          {
            "MyComponent": {
              "name": "Your Name",
              "flag": false
            },
            "YourComponent": {
              "number": 3.1415
            }
          }
        ]
        """

        let jsonData = jsonString.data(using: .utf8)!

        let nexus = Nexus()

        let family = nexus.family(requiresAll: YourComponent.self, MyComponent.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(family.count, 2)
    }

    func testEncodeFamily3() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self)
        family.createMember(with: (MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2)))
        family.createMember(with: (MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4)))
        XCTAssertEqual(family.count, 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThanOrEqual(encodedData.count, 200)
    }

    func testDecodingFamily3() throws {
        let jsonString = """
        [
          {
            "MyComponent": {
              "name": "My Name",
              "flag": true
            },
            "YourComponent": {
              "number": 1.23
            },
            "Position": {
              "x": 1,
              "y": 2
            }
          },
          {
            "MyComponent": {
              "name": "Your Name",
              "flag": false
            },
            "YourComponent": {
              "number": 3.45
            },
            "Position": {
              "x": 3,
              "y": 4
            }
          }
        ]
        """

        let jsonData = jsonString.data(using: .utf8)!

        let nexus = Nexus()

        let family = nexus.family(requiresAll: YourComponent.self, MyComponent.self, Position.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(family.count, 2)
    }
}
