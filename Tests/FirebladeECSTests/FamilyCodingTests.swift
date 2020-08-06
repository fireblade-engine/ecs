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
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 2)
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
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 2)
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
        let family2 = nexus.family(requiresAll: YourComponent.self, MyComponent.self, excludesAll: Index.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 2)
        XCTAssertEqual(family.count, 2)
        XCTAssertEqual(family2.count, 2)
    }

    func testEncodeFamily4() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self, Color.self)
        family.createMember(with: (MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3)))
        family.createMember(with: (MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6)))
        XCTAssertEqual(family.count, 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThanOrEqual(encodedData.count, 250)
    }

    func testDecodeFamily4() throws {
        let jsonString = """
        [
          {
            "Color": {
              "r": 1,
              "g": 2,
              "b": 3
            },
            "Position": {
              "x": 1,
              "y": 2
            },
            "MyComponent": {
              "name": "My Name",
              "flag": true
            },
            "YourComponent": {
              "number": 1.2300000190734863
            }
          },
          {
            "Color": {
              "r": 4,
              "g": 5,
              "b": 6
            },
            "Position": {
              "x": 3,
              "y": 4
            },
            "MyComponent": {
              "name": "Your Name",
              "flag": false
            },
            "YourComponent": {
              "number": 3.4500000476837158
            }
          }
        ]
        """

        let jsonData = jsonString.data(using: .utf8)!

        let nexus = Nexus()

        let family = nexus.family(requiresAll: YourComponent.self, MyComponent.self, Position.self, Color.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 2)
        XCTAssertEqual(family.count, 2)
    }

    func testEncodeFamily5() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self, Color.self, Party.self)
        family.createMember(with: (MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3), Party(partying: true)))
        family.createMember(with: (MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6), Party(partying: false)))
        XCTAssertEqual(family.count, 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThanOrEqual(encodedData.count, 320)
    }

    func testDecodeFamily5() throws {
        let jsonString = """
        [
          {
            "Color": {
              "r": 1,
              "g": 2,
              "b": 3
            },
            "Position": {
              "x": 1,
              "y": 2
            },
            "MyComponent": {
              "name": "My Name",
              "flag": true
            },
            "YourComponent": {
              "number": 1.23
            },
            "Party": {
              "partying": true
            }
          },
          {
            "Color": {
              "r": 4,
              "g": 5,
              "b": 6
            },
            "Position": {
              "x": 3,
              "y": 4
            },
            "MyComponent": {
              "name": "Your Name",
              "flag": false
            },
            "YourComponent": {
              "number": 3.45
            },
            "Party": {
              "partying": false
            }
          }
        ]
        """

        let jsonData = jsonString.data(using: .utf8)!

        let nexus = Nexus()

        let family = nexus.family(requiresAll: YourComponent.self, MyComponent.self, Position.self, Color.self, Party.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 2)
        XCTAssertEqual(family.count, 2)
    }

    func testFailDecodingFamily() {
        let jsonString = """
        [
          {
            "Color": {
              "r": 1,
              "g": 2,
              "b": 3
            },
            "Position": {
              "x": 1,
              "y": 2
            },
            "YourComponent": {
              "number": 1.23
            },
            "Party": {
              "partying": true
            }
          },
          {
            "Color": {
              "r": 4,
              "g": 5,
              "b": 6
            },
            "Position": {
              "x": 3,
              "y": 4
            },
            "YourComponent": {
              "number": 3.45
            },
            "Party": {
              "partying": false
            }
          }
        ]
        """
        let jsonData = jsonString.data(using: .utf8)!
        var jsonDecoder = JSONDecoder()

        let nexus = Nexus()

        let family = nexus.family(requiresAll: YourComponent.self, MyComponent.self)
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder))
    }
}
