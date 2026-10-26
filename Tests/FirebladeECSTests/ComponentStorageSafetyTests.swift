//
//  ComponentStorageSafetyTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

// Misuse of the storage traps with a specific message instead of corrupting memory. Each case runs in a child
// process; exit tests are unavailable on iOS, tvOS, watchOS and WebAssembly. Exit test bodies cannot capture
// context, so each trap is a free function.
#if os(macOS) || os(Linux) || os(Windows)

    /// Two component types that claim the same dense index: a programming error the storage must catch.
    private struct TwinA: Component, Sendable {
        static let componentIndex = 5000
    }

    private struct TwinB: Component, Sendable {
        static let componentIndex = 5000
    }

    /// A hand-assigned index above the limit of 1,048,576.
    private struct TooHigh: Component, Sendable {
        static let componentIndex = 2_000_000
    }

    private func populated() -> (Nexus.SparseSetStorage, EntityIdentifier) {
        let storage = Nexus.SparseSetStorage()
        let entity = EntityIdentifier(index: 1, generation: 0)
        storage.insertEntity(entity)
        storage.set(Position(x: 0, y: 0), for: entity)
        storage.set(Name(name: ""), for: entity)
        return (storage, entity)
    }

    // Release (-O) builds trap without printing the precondition message, so only check it in debug builds.
    private func expectTrapMessage(_ result: ExitTest.Result?, _ message: String) {
        #if DEBUG
            let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
            #expect(stderr.contains(message))
        #endif
    }

    private func structuralChangeDuringModifyTrapsBody() {
        let (storage, entity) = populated()
        _ = storage.modify(Position.self, for: entity) { _ in storage.set(Comp1(1), for: entity) }
    }

    private func destroyDuringModifyTrapsBody() {
        let (storage, entity) = populated()
        _ = storage.modify(Position.self, for: entity) { _ in storage.destroyEntity(entity) }
    }

    private func structuralChangeDuringBulkAccessTrapsBody() {
        let (storage, entity) = populated()
        storage.withComponents(of: Position.self) { _, _ in storage.remove(Name.self, from: entity) }
    }

    private func modifyInsideModifyOfTheSameTypeTrapsBody() {
        let (storage, entity) = populated()
        _ = storage.modify(Position.self, for: entity) { _ in
            _ = storage.modify(Position.self, for: entity) { _ in }
        }
    }

    private func getInsideWriteOfTheSameTypeTrapsBody() {
        let (storage, entity) = populated()
        _ = storage.modify(Position.self, for: entity) { _ in _ = storage.get(Position.self, for: entity) }
    }

    private func bulkAccessInsideWriteOfTheSameTypeTrapsBody() {
        let (storage, _) = populated()
        storage.withComponents(of: Position.self) { _, _ in storage.withComponents(of: Position.self) { _, _ in } }
    }

    private func twoTypesSharingAComponentIndexTrapBody() {
        let storage = Nexus.SparseSetStorage()
        let entity = EntityIdentifier(index: 1, generation: 0)
        storage.insertEntity(entity)
        storage.set(TwinA(), for: entity)
        _ = storage.get(TwinB.self, for: entity)
    }

    private func componentIndexAboveTheLimitTrapsBody() {
        let (storage, entity) = populated()
        storage.set(TooHigh(), for: entity)
    }

    private func settingOnADeadEntityTrapsBody() {
        let (storage, entity) = populated()
        storage.set(Comp1(1), for: EntityIdentifier(index: entity.index, generation: 1))
    }

    private func insertingAnOccupiedSlotTrapsBody() {
        let (storage, entity) = populated()
        storage.insertEntity(EntityIdentifier(index: entity.index, generation: 1))
    }

    @Suite struct ComponentStorageSafetyTests {
        @Test func structuralChangeDuringModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                structuralChangeDuringModifyTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @Test func destroyDuringModifyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                destroyDuringModifyTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @Test func structuralChangeDuringBulkAccessTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                structuralChangeDuringBulkAccessTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @Test func modifyInsideModifyOfTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                modifyInsideModifyOfTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test func getInsideWriteOfTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                getInsideWriteOfTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test func bulkAccessInsideWriteOfTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                bulkAccessInsideWriteOfTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test func twoTypesSharingAComponentIndexTrap() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                twoTypesSharingAComponentIndexTrapBody()
            }
            expectTrapMessage(result, "used by two component types")
        }

        @Test func componentIndexAboveTheLimitTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                componentIndexAboveTheLimitTrapsBody()
            }
            expectTrapMessage(result, "out of range")
        }

        @Test func settingOnADeadEntityTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                settingOnADeadEntityTrapsBody()
            }
            expectTrapMessage(result, "dead entity")
        }

        @Test func insertingAnOccupiedSlotTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                insertingAnOccupiedSlotTrapsBody()
            }
            expectTrapMessage(result, "is in use")
        }
    }

#endif
