// Generated using Sourcery 0.18.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import FirebladeECS
import XCTest

// MARK: - Family 1 test case
final class Family1Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 1)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(entity[\Comp1.value], 0)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 1)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 1)
        XCTAssertEqual(entity[\Comp1.value], 0)
    }

    func testComponentIteration() {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 1)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1) in
            XCTAssertEqual(entity.numComponents, 1)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 } }, { "Comp1":{ "value" : 0 } }, { "Comp1":{ "value" : 0 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requires: Comp1.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 2 test case
final class Family2Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 2)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 2)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 2)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 2)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 2)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2) in
            XCTAssertEqual(entity.numComponents, 2)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 3 test case
final class Family3Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 3)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 3)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 3)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 3)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 3)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3) in
            XCTAssertEqual(entity.numComponents, 3)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 4 test case
final class Family4Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2), Comp4(3)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 4)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 4)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 4)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 4)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 4)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            XCTAssertNotNil(entity[\Comp4.self])
            XCTAssertEqual(entity[\Comp4.value], 3_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4) in
            XCTAssertEqual(entity.numComponents, 4)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(entity[\Comp4.self], comp4)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 5 test case
final class Family5Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 5)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 5)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 5)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 5)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 5)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            XCTAssertNotNil(entity[\Comp4.self])
            XCTAssertEqual(entity[\Comp4.value], 3_000_000 + idx)
            XCTAssertNotNil(entity[\Comp5.self])
            XCTAssertEqual(entity[\Comp5.value], 4_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5) in
            XCTAssertEqual(entity.numComponents, 5)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(entity[\Comp4.self], comp4)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(entity[\Comp5.self], comp5)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 6 test case
final class Family6Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 6)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 6)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
            Comp6(5)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 6)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 6)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 6)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            XCTAssertNotNil(entity[\Comp4.self])
            XCTAssertEqual(entity[\Comp4.value], 3_000_000 + idx)
            XCTAssertNotNil(entity[\Comp5.self])
            XCTAssertEqual(entity[\Comp5.value], 4_000_000 + idx)
            XCTAssertNotNil(entity[\Comp6.self])
            XCTAssertEqual(entity[\Comp6.value], 5_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6) in
            XCTAssertEqual(entity.numComponents, 6)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(entity[\Comp4.self], comp4)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(entity[\Comp5.self], comp5)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            XCTAssertEqual(entity[\Comp6.self], comp6)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 7 test case
final class Family7Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5), Comp7(6)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 7)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 7)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
        XCTAssertEqual(entity[\Comp7.value], 6)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
            Comp6(5)
            Comp7(6)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 7)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 7)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
        XCTAssertEqual(entity[\Comp7.value], 6)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            XCTAssertEqual(comp7.value, 6_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 7)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            XCTAssertNotNil(entity[\Comp4.self])
            XCTAssertEqual(entity[\Comp4.value], 3_000_000 + idx)
            XCTAssertNotNil(entity[\Comp5.self])
            XCTAssertEqual(entity[\Comp5.value], 4_000_000 + idx)
            XCTAssertNotNil(entity[\Comp6.self])
            XCTAssertEqual(entity[\Comp6.value], 5_000_000 + idx)
            XCTAssertNotNil(entity[\Comp7.self])
            XCTAssertEqual(entity[\Comp7.value], 6_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7) in
            XCTAssertEqual(entity.numComponents, 7)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(entity[\Comp4.self], comp4)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(entity[\Comp5.self], comp5)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            XCTAssertEqual(entity[\Comp6.self], comp6)
            XCTAssertEqual(comp7.value, 6_000_000 + idx)
            XCTAssertEqual(entity[\Comp7.self], comp7)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Family 8 test case
final class Family8Tests: XCTestCase {
    var nexus: Nexus!

    override func setUp() {
        super.setUp()
        nexus = Nexus()
    }

    func testMemberCreation() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember(with: (Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5), Comp7(6), Comp8(7)))
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 8)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 8)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
        XCTAssertEqual(entity[\Comp7.value], 6)
        XCTAssertEqual(entity[\Comp8.value], 7)
    }

    func testMemberCreationBuilder() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
            Comp6(5)
            Comp7(6)
            Comp8(7)
        }
        XCTAssertEqual(family.count, 1)
        XCTAssertEqual(entity.numComponents, 8)
        XCTAssertEqual(nexus.numFamilies, 1)
        XCTAssertEqual(nexus.numEntities, 1)
        XCTAssertEqual(nexus.numComponents, 8)
        XCTAssertEqual(entity[\Comp1.value], 0)
        XCTAssertEqual(entity[\Comp2.value], 1)
        XCTAssertEqual(entity[\Comp3.value], 2)
        XCTAssertEqual(entity[\Comp4.value], 3)
        XCTAssertEqual(entity[\Comp5.value], 4)
        XCTAssertEqual(entity[\Comp6.value], 5)
        XCTAssertEqual(entity[\Comp7.value], 6)
        XCTAssertEqual(entity[\Comp8.value], 7)
    }

    func testComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i), Comp8(7_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8) in
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            XCTAssertEqual(comp7.value, 6_000_000 + idx)
            XCTAssertEqual(comp8.value, 7_000_000 + idx)
            idx += 1
        }
    }

    func testEntityIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i), Comp8(7_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            XCTAssertEqual(entity.numComponents, 8)
            XCTAssertNotNil(entity[\Comp1.self])
            XCTAssertEqual(entity[\Comp1.value], 0_000_000 + idx)
            XCTAssertNotNil(entity[\Comp2.self])
            XCTAssertEqual(entity[\Comp2.value], 1_000_000 + idx)
            XCTAssertNotNil(entity[\Comp3.self])
            XCTAssertEqual(entity[\Comp3.value], 2_000_000 + idx)
            XCTAssertNotNil(entity[\Comp4.self])
            XCTAssertEqual(entity[\Comp4.value], 3_000_000 + idx)
            XCTAssertNotNil(entity[\Comp5.self])
            XCTAssertEqual(entity[\Comp5.value], 4_000_000 + idx)
            XCTAssertNotNil(entity[\Comp6.self])
            XCTAssertEqual(entity[\Comp6.value], 5_000_000 + idx)
            XCTAssertNotNil(entity[\Comp7.self])
            XCTAssertEqual(entity[\Comp7.value], 6_000_000 + idx)
            XCTAssertNotNil(entity[\Comp8.self])
            XCTAssertEqual(entity[\Comp8.value], 7_000_000 + idx)
            idx += 1
        }
    }

    func testEntityComponentIteration() {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i), Comp8(7_000_000 + i)))
        }
        XCTAssertEqual(family.count, 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8) in
            XCTAssertEqual(entity.numComponents, 8)
            XCTAssertEqual(comp1.value, 0_000_000 + idx)
            XCTAssertEqual(entity[\Comp1.self], comp1)
            XCTAssertEqual(comp2.value, 1_000_000 + idx)
            XCTAssertEqual(entity[\Comp2.self], comp2)
            XCTAssertEqual(comp3.value, 2_000_000 + idx)
            XCTAssertEqual(entity[\Comp3.self], comp3)
            XCTAssertEqual(comp4.value, 3_000_000 + idx)
            XCTAssertEqual(entity[\Comp4.self], comp4)
            XCTAssertEqual(comp5.value, 4_000_000 + idx)
            XCTAssertEqual(entity[\Comp5.self], comp5)
            XCTAssertEqual(comp6.value, 5_000_000 + idx)
            XCTAssertEqual(entity[\Comp6.self], comp6)
            XCTAssertEqual(comp7.value, 6_000_000 + idx)
            XCTAssertEqual(entity[\Comp7.self], comp7)
            XCTAssertEqual(comp8.value, 7_000_000 + idx)
            XCTAssertEqual(entity[\Comp8.self], comp8)
            idx += 1
        }
    }

    func testFamilyEncoding() throws {
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (Comp1(0_000_000 + i), Comp2(1_000_000 + i), Comp3(2_000_000 + i), Comp4(3_000_000 + i), Comp5(4_000_000 + i), Comp6(5_000_000 + i), Comp7(6_000_000 + i), Comp8(7_000_000 + i)))
        }
        XCTAssertEqual(family.count, 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        XCTAssertGreaterThan(encodedData.count, 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            XCTFail("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        XCTAssertEqual(String(jsonString.prefix(expectedStart.count)), String(expectedStart))
        let expectedEnd = "}]"
        XCTAssertEqual(String(jsonString.suffix(expectedEnd.count)), String(expectedEnd))
    }

    func testFamilyDecoding() throws {
        let jsonString: String = """
                                 [ { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } }, { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } } ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        XCTAssertEqual(newEntities.count, 3)
        XCTAssertEqual(family.count, 3)
    }

    func testFamilyFailDecoding() {
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        XCTAssertTrue(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        XCTAssertThrowsError(try family.decodeMembers(from: jsonData, using: &jsonDecoder)) { error in
            switch error {
            case let decodingError as DecodingError:
                switch decodingError {
                case .keyNotFound:
                    break
                default:
                    XCTFail("Wrong error provided \(error)")
                }
            default:
                XCTFail("Wrong error provided \(error)")
            }
        }
    }
}

// MARK: - Components
final class Comp1: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp1: Equatable {
    static func == (lhs: Comp1, rhs: Comp1) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp1: Codable { }

final class Comp2: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp2: Equatable {
    static func == (lhs: Comp2, rhs: Comp2) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp2: Codable { }

final class Comp3: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp3: Equatable {
    static func == (lhs: Comp3, rhs: Comp3) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp3: Codable { }

final class Comp4: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp4: Equatable {
    static func == (lhs: Comp4, rhs: Comp4) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp4: Codable { }

final class Comp5: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp5: Equatable {
    static func == (lhs: Comp5, rhs: Comp5) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp5: Codable { }

final class Comp6: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp6: Equatable {
    static func == (lhs: Comp6, rhs: Comp6) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp6: Codable { }

final class Comp7: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp7: Equatable {
    static func == (lhs: Comp7, rhs: Comp7) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp7: Codable { }

final class Comp8: Component {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp8: Equatable {
    static func == (lhs: Comp8, rhs: Comp8) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp8: Codable { }
