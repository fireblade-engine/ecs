// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import FirebladeECS
import Testing
import Foundation

// MARK: - Family 1 test case
@Suite struct Family1Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 1)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 1)
        #expect(entity[\Comp1.value] == 0)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 1)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 1)
        #expect(entity[\Comp1.value] == 0)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 1)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1) in
            #expect(entity.numComponents == 1)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 } },
                                   { "Comp1":{ "value" : 0 } },
                                   { "Comp1":{ "value" : 0 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requires: Comp1.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 2 test case
@Suite struct Family2Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 2)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 2)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 2)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 2)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 2)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2) in
            #expect(entity.numComponents == 2)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 3 test case
@Suite struct Family3Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 3)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 3)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 3)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 3)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 3)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3) in
            #expect(entity.numComponents == 3)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 4 test case
@Suite struct Family4Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2), Comp4(3)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 4)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 4)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 4)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 4)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 4)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] != nil)
            #expect(entity[\Comp4.value] == 3 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4) in
            #expect(entity.numComponents == 4)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] == comp4)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 5 test case
@Suite struct Family5Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 5)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 5)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 5)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 5)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 5)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] != nil)
            #expect(entity[\Comp4.value] == 3 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] != nil)
            #expect(entity[\Comp5.value] == 4 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5) in
            #expect(entity.numComponents == 5)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] == comp4)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] == comp5)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 6 test case
@Suite struct Family6Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 6)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 6)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
            Comp6(5)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 6)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 6)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 6)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] != nil)
            #expect(entity[\Comp4.value] == 3 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] != nil)
            #expect(entity[\Comp5.value] == 4 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] != nil)
            #expect(entity[\Comp6.value] == 5 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6) in
            #expect(entity.numComponents == 6)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] == comp4)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] == comp5)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] == comp6)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 7 test case
@Suite struct Family7Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5), Comp7(6)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 7)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 7)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
        #expect(entity[\Comp7.value] == 6)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        let entity = family.createMember {
            Comp1(0)
            Comp2(1)
            Comp3(2)
            Comp4(3)
            Comp5(4)
            Comp6(5)
            Comp7(6)
        }
        #expect(family.count == 1)
        #expect(entity.numComponents == 7)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 7)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
        #expect(entity[\Comp7.value] == 6)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            #expect(comp7.value == 6 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 7)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] != nil)
            #expect(entity[\Comp4.value] == 3 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] != nil)
            #expect(entity[\Comp5.value] == 4 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] != nil)
            #expect(entity[\Comp6.value] == 5 * 1_000_000 + idx)
            #expect(entity[\Comp7.self] != nil)
            #expect(entity[\Comp7.value] == 6 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7) in
            #expect(entity.numComponents == 7)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] == comp4)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] == comp5)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] == comp6)
            #expect(comp7.value == 6 * 1_000_000 + idx)
            #expect(entity[\Comp7.self] == comp7)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Family 8 test case
@Suite struct Family8Tests {
    @Test func memberCreation() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        let entity = family.createMember(with: (
            Comp1(0), Comp2(1), Comp3(2), Comp4(3), Comp5(4), Comp6(5), Comp7(6), Comp8(7)
        ))
        #expect(family.count == 1)
        #expect(entity.numComponents == 8)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 8)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
        #expect(entity[\Comp7.value] == 6)
        #expect(entity[\Comp8.value] == 7)
    }

    @Test func memberCreationBuilder() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
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
        #expect(family.count == 1)
        #expect(entity.numComponents == 8)
        #expect(nexus.numFamilies == 1)
        #expect(nexus.numEntities == 1)
        #expect(nexus.numComponents == 8)
        #expect(entity[\Comp1.value] == 0)
        #expect(entity[\Comp2.value] == 1)
        #expect(entity[\Comp3.value] == 2)
        #expect(entity[\Comp4.value] == 3)
        #expect(entity[\Comp5.value] == 4)
        #expect(entity[\Comp6.value] == 5)
        #expect(entity[\Comp7.value] == 6)
        #expect(entity[\Comp8.value] == 7)
    }

    @Test func componentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i), Comp8(7 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.forEach { (comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8) in
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            #expect(comp7.value == 6 * 1_000_000 + idx)
            #expect(comp8.value == 7 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i), Comp8(7 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entities.forEach { (entity) in
            #expect(entity.numComponents == 8)
            #expect(entity[\Comp1.self] != nil)
            #expect(entity[\Comp1.value] == 0 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] != nil)
            #expect(entity[\Comp2.value] == 1 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] != nil)
            #expect(entity[\Comp3.value] == 2 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] != nil)
            #expect(entity[\Comp4.value] == 3 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] != nil)
            #expect(entity[\Comp5.value] == 4 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] != nil)
            #expect(entity[\Comp6.value] == 5 * 1_000_000 + idx)
            #expect(entity[\Comp7.self] != nil)
            #expect(entity[\Comp7.value] == 6 * 1_000_000 + idx)
            #expect(entity[\Comp8.self] != nil)
            #expect(entity[\Comp8.value] == 7 * 1_000_000 + idx)
            idx += 1
        }
    }

    @Test func entityComponentIteration() {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        for i in 0..<10_000 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i), Comp8(7 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 10_000)
        var idx: Int = 0
        family.entityAndComponents.forEach { (entity, comp1, comp2, comp3, comp4, comp5, comp6, comp7, comp8) in
            #expect(entity.numComponents == 8)
            #expect(comp1.value == 0 * 1_000_000 + idx)
            #expect(entity[\Comp1.self] == comp1)
            #expect(comp2.value == 1 * 1_000_000 + idx)
            #expect(entity[\Comp2.self] == comp2)
            #expect(comp3.value == 2 * 1_000_000 + idx)
            #expect(entity[\Comp3.self] == comp3)
            #expect(comp4.value == 3 * 1_000_000 + idx)
            #expect(entity[\Comp4.self] == comp4)
            #expect(comp5.value == 4 * 1_000_000 + idx)
            #expect(entity[\Comp5.self] == comp5)
            #expect(comp6.value == 5 * 1_000_000 + idx)
            #expect(entity[\Comp6.self] == comp6)
            #expect(comp7.value == 6 * 1_000_000 + idx)
            #expect(entity[\Comp7.self] == comp7)
            #expect(comp8.value == 7 * 1_000_000 + idx)
            #expect(entity[\Comp8.self] == comp8)
            idx += 1
        }
    }

    @Test func familyEncoding() throws {
        let nexus = Nexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        for i in 0..<100 {
            family.createMember(with: (
                Comp1(0 * 1_000_000 + i), Comp2(1 * 1_000_000 + i), Comp3(2 * 1_000_000 + i), Comp4(3 * 1_000_000 + i), Comp5(4 * 1_000_000 + i), Comp6(5 * 1_000_000 + i), Comp7(6 * 1_000_000 + i), Comp8(7 * 1_000_000 + i)
            ))
        }
        #expect(family.count == 100)

        var jsonEncoder = JSONEncoder()
        let encodedData = try family.encodeMembers(using: &jsonEncoder)
        #expect(encodedData.count > 10)
        guard let jsonString = String(data: encodedData, encoding: .utf8) else {
            Issue.record("Failed to read string from encoded data \(encodedData.count)")
            return
        }
        let expectedStart = "[{"
        #expect(String(jsonString.prefix(expectedStart.count)) == expectedStart)
        let expectedEnd = "}]"
        #expect(String(jsonString.suffix(expectedEnd.count)) == expectedEnd)
    }

    @Test func familyDecoding() throws {
        let nexus = Nexus()
        let jsonString: String = """
                                 [ 
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } },
                                   { "Comp1":{ "value" : 0 },"Comp2":{ "value" : 1 },"Comp3":{ "value" : 2 },"Comp4":{ "value" : 3 },"Comp5":{ "value" : 4 },"Comp6":{ "value" : 5 },"Comp7":{ "value" : 6 },"Comp8":{ "value" : 7 } }
                                 ]
                                 """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        let newEntities = try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        #expect(newEntities.count == 3)
        #expect(family.count == 3)
    }

    @Test func familyFailDecoding() {
        let nexus = Nexus()
        let jsonString = """
                         [{ "SomeOtherComp": { "someValue": "fail" } }]
                         """
        guard let jsonData = jsonString.data(using: .utf8) else {
            Issue.record("Failed to read data from json string \(jsonString.count)")
            return
        }
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self, Comp3.self, Comp4.self, Comp5.self, Comp6.self, Comp7.self, Comp8.self)
        #expect(family.isEmpty)
        var jsonDecoder = JSONDecoder()
        #expect(throws: Error.self) {
            try family.decodeMembers(from: jsonData, using: &jsonDecoder)
        }
    }
}

// MARK: - Components
final class Comp1: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp1: Equatable {
    static func == (lhs: Comp1, rhs: Comp1) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp1: Codable { }

final class Comp2: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp2: Equatable {
    static func == (lhs: Comp2, rhs: Comp2) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp2: Codable { }

final class Comp3: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp3: Equatable {
    static func == (lhs: Comp3, rhs: Comp3) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp3: Codable { }

final class Comp4: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp4: Equatable {
    static func == (lhs: Comp4, rhs: Comp4) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp4: Codable { }

final class Comp5: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp5: Equatable {
    static func == (lhs: Comp5, rhs: Comp5) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp5: Codable { }

final class Comp6: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp6: Equatable {
    static func == (lhs: Comp6, rhs: Comp6) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp6: Codable { }

final class Comp7: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp7: Equatable {
    static func == (lhs: Comp7, rhs: Comp7) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp7: Codable { }

final class Comp8: Component, @unchecked Sendable {
    var value: Int
    init(_ value: Int) { self.value = value }
}
extension Comp8: Equatable {
    static func == (lhs: Comp8, rhs: Comp8) -> Bool {
        lhs === rhs && lhs.value == rhs.value
    }
}
extension Comp8: Codable { }

