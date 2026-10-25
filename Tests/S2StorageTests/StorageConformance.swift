//
//  StorageConformance.swift
//  S2StorageTests
//

import S2Storage
import Testing

/// A test body that runs against a nexus on any storage, so every storage gets the same conformance suite.
protocol StorageTest {
    static func run(_ storage: S2Nexus)
}

extension S2Nexus.StorageKind: CustomTestStringConvertible {
    public var testDescription: String {
        switch self {
        case .sparseSet: "sparse set"
        case .archetype: "archetype"
        }
    }

    func run<T: StorageTest>(_: T.Type) {
        T.run(S2Nexus(storage: self))
    }
}

extension S2Nexus {
    func makeEntities(_ count: Int) -> [EntityID] {
        (0 ..< count).map { _ in createEntity() }
    }
}
