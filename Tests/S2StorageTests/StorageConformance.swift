//
//  StorageConformance.swift
//  S2StorageTests
//

import S2Storage
import Testing

/// A test body that runs against any storage, so every storage gets the same conformance suite.
protocol StorageTest {
    static func run<S: NexusStorageProviding>(_ storage: S)
}

/// The storages under test; the parameter of every conformance test.
enum StorageKind: CaseIterable, CustomTestStringConvertible, Sendable {
    case sparseSet
    case archetype
    case blockSparseSet

    var testDescription: String {
        switch self {
        case .sparseSet: "SparseSetStorage"
        case .archetype: "ArchetypeStorage"
        case .blockSparseSet: "BlockSparseSetStorage"
        }
    }

    func run<T: StorageTest>(_: T.Type) {
        switch self {
        case .sparseSet: T.run(SparseSetStorage())
        case .archetype: T.run(ArchetypeStorage())
        case .blockSparseSet: T.run(BlockSparseSetStorage())
        }
    }
}

extension NexusStorageProviding {
    func makeEntities(_ count: Int) -> [EntityID] {
        (0 ..< count).map { _ in createEntity() }
    }
}
