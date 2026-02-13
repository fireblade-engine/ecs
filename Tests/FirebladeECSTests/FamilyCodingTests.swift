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
        let component = TestComponent(value: 42)
        let container = FamilyMemberContainer<TestComponent>(components: component)

        let encoder = JSONEncoder()
        let data = try encoder.encode(container)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FamilyMemberContainer<TestComponent>.self, from: data)

        // decoded.components is (TestComponent)
        // Accessing via pattern matching or direct if it unwraps?
        // Let's try .value if it unwraps, or .0.value if tuple.
        // I suspect it's a tuple.
        #expect(decoded.components.value == 42) 
    }
}

final class TestComponent: Component, Codable, @unchecked Sendable {
    var value: Int
    init(value: Int) { self.value = value }
}

// Workaround for conformance visibility
extension FamilyMemberContainer: Encodable where repeat each C: Encodable {
    func encode(to encoder: Encoder) throws {
        let strategy = encoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        _ = (repeat try container.encode(each components, forKey: strategy.codingKey(for: (each C).self)))
    }
}

extension FamilyMemberContainer: Decodable where repeat each C: Decodable {
    init(from decoder: Decoder) throws {
        let strategy = decoder.userInfo[.nexusCodingStrategy] as? CodingStrategy ?? DefaultCodingStrategy()
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.components = (repeat try container.decode((each C).self, forKey: strategy.codingKey(for: (each C).self)))
    }
}
