//
//  StorageSafetyTests.swift
//  S2StorageTests
//

import S2Storage
import Testing

// The D4 contract: misuse traps with a specific message instead of corrupting memory. Each case runs in a
// child process; exit tests are unavailable on iOS, tvOS, watchOS and WebAssembly. Exit test bodies cannot
// capture context, so each trap is a free function called with a literal storage kind.
#if os(macOS) || os(Linux) || os(Windows)

/// Two component types that claim the same dense index: a programming error the storages must catch.
private struct TwinA: Component {
    static let componentIndex = 100
}

private struct TwinB: Component {
    static let componentIndex = 100
}

private func populated(_ kind: S2Nexus.StorageKind) -> (S2Nexus, EntityID) {
    let storage = S2Nexus(storage: kind)
    let entity = storage.createEntity()
    storage.set(Position(), for: entity)
    storage.set(Velocity(), for: entity)
    return (storage, entity)
}

// Release (-O) builds trap without printing the precondition message, so only check it in debug builds.
private func expectTrapMessage(_ result: ExitTest.Result?, _ message: String) {
    #if DEBUG
    let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
    #expect(stderr.contains(message))
    #endif
}

private func structuralChangeDuringIterationTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, entity) = populated(kind)
    storage.forEach(reading: Position.self) { _ in storage.set(Mass(), for: entity) }
}

private func destroyDuringModifyTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, entity) = populated(kind)
    _ = storage.modify(Position.self, for: entity) { _ in storage.destroyEntity(entity) }
}

private func nestedWritingIterationTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, _) = populated(kind)
    storage.forEach(reading: Position.self, writing: Velocity.self) { _, _ in
        storage.forEach(reading: Position.self, writing: Velocity.self) { _, _ in }
    }
}

private func modifyInsideModifyOfTheSameTypeTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, entity) = populated(kind)
    _ = storage.modify(Position.self, for: entity) { _ in
        _ = storage.modify(Position.self, for: entity) { _ in }
    }
}

private func getInsideWriteOfTheSameTypeTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, entity) = populated(kind)
    _ = storage.modify(Position.self, for: entity) { _ in _ = storage.get(Position.self, for: entity) }
}

private func iterationInsideWriteOfTheSameTypeTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, _) = populated(kind)
    storage.withComponents(of: Position.self) { _, _ in storage.forEach(reading: Position.self) { _ in } }
}

private func readingAndWritingOneTypeInOneIterationTrapsBody(_ kind: S2Nexus.StorageKind) {
    let (storage, _) = populated(kind)
    storage.forEach(reading: Position.self, writing: Position.self) { _, _ in }
}

private func twoTypesSharingAComponentIndexTrapBody(_ kind: S2Nexus.StorageKind) {
    let storage = S2Nexus(storage: kind)
    let entity = storage.createEntity()
    storage.set(TwinA(), for: entity)
    _ = storage.get(TwinB.self, for: entity)
}

@Suite struct StorageSafetyTests {
    @Test func structuralChangeDuringIterationTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            structuralChangeDuringIterationTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "structural change")
    }

    @Test func structuralChangeDuringIterationTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            structuralChangeDuringIterationTrapsBody(.archetype)
        }
        expectTrapMessage(result, "structural change")
    }

    @Test func destroyDuringModifyTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            destroyDuringModifyTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "structural change")
    }

    @Test func destroyDuringModifyTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            destroyDuringModifyTrapsBody(.archetype)
        }
        expectTrapMessage(result, "structural change")
    }

    @Test func nestedWritingIterationTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            nestedWritingIterationTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "nested write access")
    }

    @Test func nestedWritingIterationTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            nestedWritingIterationTrapsBody(.archetype)
        }
        expectTrapMessage(result, "nested write access")
    }

    @Test func modifyInsideModifyOfTheSameTypeTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            modifyInsideModifyOfTheSameTypeTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "nested write access")
    }

    @Test func modifyInsideModifyOfTheSameTypeTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            modifyInsideModifyOfTheSameTypeTrapsBody(.archetype)
        }
        expectTrapMessage(result, "nested write access")
    }

    @Test func getInsideWriteOfTheSameTypeTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            getInsideWriteOfTheSameTypeTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "during a write access")
    }

    @Test func getInsideWriteOfTheSameTypeTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            getInsideWriteOfTheSameTypeTrapsBody(.archetype)
        }
        expectTrapMessage(result, "during a write access")
    }

    @Test func iterationInsideWriteOfTheSameTypeTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            iterationInsideWriteOfTheSameTypeTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "during a write access")
    }

    @Test func iterationInsideWriteOfTheSameTypeTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            iterationInsideWriteOfTheSameTypeTrapsBody(.archetype)
        }
        expectTrapMessage(result, "during a write access")
    }

    @Test func readingAndWritingOneTypeInOneIterationTraps_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            readingAndWritingOneTypeInOneIterationTrapsBody(.sparseSet)
        }
        expectTrapMessage(result, "cannot be read and written")
    }

    @Test func readingAndWritingOneTypeInOneIterationTraps_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            readingAndWritingOneTypeInOneIterationTrapsBody(.archetype)
        }
        expectTrapMessage(result, "cannot be read and written")
    }

    @Test func twoTypesSharingAComponentIndexTrap_sparseSet() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            twoTypesSharingAComponentIndexTrapBody(.sparseSet)
        }
        expectTrapMessage(result, "used by two component types")
    }

    @Test func twoTypesSharingAComponentIndexTrap_archetype() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            twoTypesSharingAComponentIndexTrapBody(.archetype)
        }
        expectTrapMessage(result, "used by two component types")
    }
}

#endif
