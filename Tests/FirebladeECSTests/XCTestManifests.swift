#if !canImport(ObjectiveC)
import XCTest

extension ComponentIdentifierTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ComponentIdentifierTests = [
        ("testMirrorAsStableIdentifier", testMirrorAsStableIdentifier),
        ("testStringDescribingAsStableIdentifier", testStringDescribingAsStableIdentifier)
    ]
}

extension ComponentTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ComponentTests = [
        ("testComponentIdentifier", testComponentIdentifier)
    ]
}

extension EntityCreationTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__EntityCreationTests = [
        ("testBulkCreateEntitiesMultipleComponents", testBulkCreateEntitiesMultipleComponents),
        ("testBulkCreateEntitiesOneComponent", testBulkCreateEntitiesOneComponent),
        ("testCreateEntityMultipleComponents", testCreateEntityMultipleComponents),
        ("testCreateEntityOneComponent", testCreateEntityOneComponent)
    ]
}

extension EntityTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__EntityTests = [
        ("testAllComponentsOfEntity", testAllComponentsOfEntity),
        ("testEntityEquality", testEntityEquality),
        ("testEntityIdentifierAndIndex", testEntityIdentifierAndIndex),
        ("testEntityIdGenerator", testEntityIdGenerator),
        ("testEntitySubscripts", testEntitySubscripts),
        ("testRemoveAllComponentsFromEntity", testRemoveAllComponentsFromEntity)
    ]
}

extension FamilyCodingTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FamilyCodingTests = [
        ("testDecodeFamily4", testDecodeFamily4),
        ("testDecodeFamily5", testDecodeFamily5),
        ("testDecodingFamily1", testDecodingFamily1),
        ("testDecodingFamily2", testDecodingFamily2),
        ("testDecodingFamily3", testDecodingFamily3),
        ("testEncodeFamily2", testEncodeFamily2),
        ("testEncodeFamily3", testEncodeFamily3),
        ("testEncodeFamily4", testEncodeFamily4),
        ("testEncodeFamily5", testEncodeFamily5),
        ("testEncodingFamily1", testEncodingFamily1),
        ("testFailDecodingFamily", testFailDecodingFamily)
    ]
}

extension FamilyTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FamilyTests = [
        ("testFamilyAbandoned", testFamilyAbandoned),
        ("testFamilyBulkDestroy", testFamilyBulkDestroy),
        ("testFamilyCreateMembers", testFamilyCreateMembers),
        ("testFamilyCreation", testFamilyCreation),
        ("testFamilyExchange", testFamilyExchange),
        ("testFamilyLateMember", testFamilyLateMember),
        ("testFamilyMemberBasicIteration", testFamilyMemberBasicIteration),
        ("testFamilyReuse", testFamilyReuse)
    ]
}

extension FamilyTraitsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FamilyTraitsTests = [
        ("testTraitCommutativity", testTraitCommutativity),
        ("testTraitMatching", testTraitMatching)
    ]
}

extension HashingTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__HashingTests = [
        ("testCollisionsInCritialRange", testCollisionsInCritialRange),
        ("testStringHashes", testStringHashes)
    ]
}

extension NexusTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__NexusTests = [
        ("testComponentCreation", testComponentCreation),
        ("testComponentDeletion", testComponentDeletion),
        ("testComponentRetrieval", testComponentRetrieval),
        ("testComponentUniqueness", testComponentUniqueness),
        ("testEntityCreate", testEntityCreate),
        ("testEntityDestroy", testEntityDestroy)
    ]
}

extension SceneGraphTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SceneGraphTests = [
        ("testAddChild", testAddChild),
        ("testDescendRelativesOnlyFamilyMembers", testDescendRelativesOnlyFamilyMembers),
        ("testDescendRelativesSimple", testDescendRelativesSimple),
        ("testRemoveAllChildren", testRemoveAllChildren),
        ("testRemoveChild", testRemoveChild)
    ]
}

extension SingleTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SingleTests = [
        ("testSingleCreation", testSingleCreation),
        ("testSingleCreationOnExistingFamilyMember", testSingleCreationOnExistingFamilyMember),
        ("testSingleEntityAndComponentCreation", testSingleEntityAndComponentCreation),
        ("testSingleReuse", testSingleReuse)
    ]
}

extension SparseSetTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SparseSetTests = [
        ("testAlternativeKey", testAlternativeKey),
        ("testSparseSetAdd", testSparseSetAdd),
        ("testSparseSetAddAndReplace", testSparseSetAddAndReplace),
        ("testSparseSetClear", testSparseSetClear),
        ("testSparseSetDoubleRemove", testSparseSetDoubleRemove),
        ("testSparseSetGet", testSparseSetGet),
        ("testSparseSetNonCongiuousData", testSparseSetNonCongiuousData),
        ("testSparseSetReduce", testSparseSetReduce),
        ("testSparseSetRemove", testSparseSetRemove),
        ("testSparseSetRemoveAndAdd", testSparseSetRemoveAndAdd),
        ("testSparseSetRemoveNonPresent", testSparseSetRemoveNonPresent),
        ("testStartEndIndex", testStartEndIndex),
        ("testSubscript", testSubscript)
    ]
}

extension SystemsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SystemsTests = [
        ("testSystemsUpdate", testSystemsUpdate)
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ComponentIdentifierTests.__allTests__ComponentIdentifierTests),
        testCase(ComponentTests.__allTests__ComponentTests),
        testCase(EntityCreationTests.__allTests__EntityCreationTests),
        testCase(EntityTests.__allTests__EntityTests),
        testCase(FamilyCodingTests.__allTests__FamilyCodingTests),
        testCase(FamilyTests.__allTests__FamilyTests),
        testCase(FamilyTraitsTests.__allTests__FamilyTraitsTests),
        testCase(HashingTests.__allTests__HashingTests),
        testCase(NexusTests.__allTests__NexusTests),
        testCase(SceneGraphTests.__allTests__SceneGraphTests),
        testCase(SingleTests.__allTests__SingleTests),
        testCase(SparseSetTests.__allTests__SparseSetTests),
        testCase(SystemsTests.__allTests__SystemsTests)
    ]
}
#endif
