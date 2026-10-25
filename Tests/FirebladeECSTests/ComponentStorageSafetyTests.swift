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

    private func populated(_ kind: Nexus.StorageKind) -> (Nexus.Backend, EntityIdentifier) {
        let storage = Nexus.Backend(kind)
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

    private func structuralChangeDuringModifyTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        _ = storage.modify(Position.self, for: entity) { _ in storage.set(Comp1(1), for: entity) }
    }

    private func destroyDuringModifyTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        _ = storage.modify(Position.self, for: entity) { _ in storage.destroyEntity(entity) }
    }

    private func structuralChangeDuringBulkAccessTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        storage.withComponents(of: Position.self) { _, _ in storage.remove(componentIndex: Name.componentIndex, from: entity) }
    }

    private func modifyInsideModifyOfTheSameTypeTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        _ = storage.modify(Position.self, for: entity) { _ in
            _ = storage.modify(Position.self, for: entity) { _ in }
        }
    }

    private func getInsideWriteOfTheSameTypeTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        _ = storage.modify(Position.self, for: entity) { _ in _ = storage.get(Position.self, for: entity) }
    }

    private func bulkAccessInsideWriteOfTheSameTypeTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, _) = populated(kind)
        storage.withComponents(of: Position.self) { _, _ in storage.withComponents(of: Position.self) { _, _ in } }
    }

    private func twoTypesSharingAComponentIndexTrapBody(_ kind: Nexus.StorageKind) {
        let storage = Nexus.Backend(kind)
        let entity = EntityIdentifier(index: 1, generation: 0)
        storage.insertEntity(entity)
        storage.set(TwinA(), for: entity)
        _ = storage.get(TwinB.self, for: entity)
    }

    private func componentIndexAboveTheLimitTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        storage.set(TooHigh(), for: entity)
    }

    private func settingOnADeadEntityTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        storage.set(Comp1(1), for: EntityIdentifier(index: entity.index, generation: 1))
    }

    private func insertingAnOccupiedSlotTrapsBody(_ kind: Nexus.StorageKind) {
        let (storage, entity) = populated(kind)
        storage.insertEntity(EntityIdentifier(index: entity.index, generation: 1))
    }

    @Suite struct ComponentStorageSafetyTests {
        @Test(arguments: Nexus.StorageKind.allCases) func structuralChangeDuringModifyTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    structuralChangeDuringModifyTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    structuralChangeDuringModifyTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func destroyDuringModifyTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    destroyDuringModifyTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    destroyDuringModifyTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func structuralChangeDuringBulkAccessTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    structuralChangeDuringBulkAccessTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    structuralChangeDuringBulkAccessTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func modifyInsideModifyOfTheSameTypeTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    modifyInsideModifyOfTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    modifyInsideModifyOfTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func getInsideWriteOfTheSameTypeTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    getInsideWriteOfTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    getInsideWriteOfTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func bulkAccessInsideWriteOfTheSameTypeTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    bulkAccessInsideWriteOfTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    bulkAccessInsideWriteOfTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func twoTypesSharingAComponentIndexTrap(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    twoTypesSharingAComponentIndexTrapBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    twoTypesSharingAComponentIndexTrapBody(.archetype)
                }
            }
            expectTrapMessage(result, "used by two component types")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func componentIndexAboveTheLimitTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    componentIndexAboveTheLimitTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    componentIndexAboveTheLimitTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "out of range")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func settingOnADeadEntityTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    settingOnADeadEntityTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    settingOnADeadEntityTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "dead entity")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func insertingAnOccupiedSlotTraps(_ kind: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch kind {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    insertingAnOccupiedSlotTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    insertingAnOccupiedSlotTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "is in use")
        }
    }

#endif
