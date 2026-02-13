//
//  FamilyCodingTests.swift
//
//
//  Created by Christian Treffs on 22.07.20.
//

import FirebladeECS
import Testing
import Foundation

@Suite struct FamilyCodingTests {
    @Test func encodingFamily1() throws {
        let nexus = Nexus()

        let family = nexus.family(requires: MyComponent.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true))
        family.createMember(with: MyComponent(name: "Your Name", flag: false))
        #expect(family.count == 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count >= 90)
    }

    @Test func decodingFamily1() throws {
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
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 2)
        #expect(family.count == 2)
    }

    @Test func encodeFamily2() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23))
        family.createMember(with: MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45))
        #expect(family.count == 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count >= 91)
    }

    @Test func decodingFamily2() throws {
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
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 2)
        #expect(family.count == 2)
    }

    @Test func encodeFamily3() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2))
        family.createMember(with: MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4))
        #expect(family.count == 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count >= 200)
    }

    @Test func decodingFamily3() throws {
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
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 2)
        #expect(family.count == 2)
        #expect(family2.count == 2)
    }

    @Test func encodeFamily4() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self, Color.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3))
        family.createMember(with: MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6))
        #expect(family.count == 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count >= 250)
    }

    @Test func decodeFamily4() throws {
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
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 2)
        #expect(family.count == 2)
    }

    @Test func encodeFamily5() throws {
        let nexus = Nexus()

        let family = nexus.family(requiresAll: MyComponent.self, YourComponent.self, Position.self, Color.self, Party.self)
        family.createMember(with: MyComponent(name: "My Name", flag: true), YourComponent(number: 1.23), Position(x: 1, y: 2), Color(r: 1, g: 2, b: 3), Party(partying: true))
        family.createMember(with: MyComponent(name: "Your Name", flag: false), YourComponent(number: 3.45), Position(x: 3, y: 4), Color(r: 4, g: 5, b: 6), Party(partying: false))
        #expect(family.count == 2)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count >= 320)
    }

    @Test func decodeFamily5() throws {
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
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 2)
        #expect(family.count == 2)
    }

    @Test func failDecodingFamily() {
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
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }

    @Test func codingStrategyFallback() throws {
        let component = MyComponent(name: "A", flag: true)
        let container = FamilyMemberContainer<MyComponent>(components: component)

        let encoder = JSONEncoder()
        // No user info set, so it should fallback to DefaultCodingStrategy
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        // No user info set, so it should fallback to DefaultCodingStrategy
        let decoded = try decoder.decode(FamilyMemberContainer<MyComponent>.self, from: data)

        #expect(decoded.components.count == 1)
        #expect(decoded.components[0].name == "A")
    }
}


struct FamilyMemberContainer<each C: Component> {
    let components: (repeat each C)
}

extension FamilyMemberContainer: Encodable where repeat each C: Encodable { }
extension FamilyMemberContainer: Decodable where repeat each C: Decodable { }
