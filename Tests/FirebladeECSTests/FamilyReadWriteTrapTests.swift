//
//  FamilyReadWriteTrapTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

// Misuse of the read/write iteration traps with a message. Each case runs in a child process; exit tests are
// unavailable on iOS, tvOS, watchOS and WebAssembly. Exit test bodies cannot capture context, so each trap is a free function.
#if os(macOS) || os(Linux) || os(Windows)

    private func family(_ storage: Nexus.StorageKind) -> (Nexus, Family<Comp1, Comp2>) {
        let nexus = Nexus(storage: storage)
        for number in 0 ..< 3 {
            nexus.createEntity(with: Comp1(number), Comp2(number), Comp3(number))
        }
        return (nexus, nexus.family(requiresAll: Comp1.self, Comp2.self))
    }

    // Release (-O) builds trap without printing the precondition message, so only check it in debug builds.
    private func expectTrapMessage(_ result: ExitTest.Result?, _ message: String) {
        #if DEBUG
            let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
            #expect(stderr.contains(message))
        #endif
    }

    private func creatingAnEntityTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp1.self, writing: Comp2.self) { _, _ in nexus.createEntity() }
    }

    private func addingAComponentTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        family.forEach(reading: Comp1.self) { _ in entity.set(Comp4(1)) }
    }

    private func readingAWrittenTypeThroughTheNexusTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp2.self) { _ in
            _ = family.entities.first { _ in true }?.get(Comp2.self)
        }
    }

    private func readingAndWritingTheSameTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp1.self, writing: Comp1.self) { _, _ in }
    }

    private func writingTheSameTypeTwiceTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self, Comp1.self) { _, _ in }
    }

    private func nestedWriteOfTheSameTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self) { _ in
            family.forEach(writing: Comp1.self) { _ in }
        }
    }

    private func nestedReadOfAWrittenTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self) { _ in
            family.forEach(reading: Comp1.self) { _ in }
        }
    }

    private func typeNotRequiredByTheFamilyTrapsBody(_ storage: Nexus.StorageKind) {
        let (nexus, family) = family(storage)
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp3.self) { _ in }
    }

    @Suite struct FamilyReadWriteTrapTests {
        @Test(arguments: Nexus.StorageKind.allCases) func creatingAnEntityTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func addingAComponentTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    addingAComponentTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    addingAComponentTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func readingAWrittenTypeThroughTheNexusTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAWrittenTypeThroughTheNexusTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAWrittenTypeThroughTheNexusTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func readingAndWritingTheSameTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAndWritingTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAndWritingTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func writingTheSameTypeTwiceTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    writingTheSameTypeTwiceTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    writingTheSameTypeTwiceTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func nestedWriteOfTheSameTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedWriteOfTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedWriteOfTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func nestedReadOfAWrittenTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedReadOfAWrittenTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedReadOfAWrittenTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test(arguments: Nexus.StorageKind.allCases) func typeNotRequiredByTheFamilyTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    typeNotRequiredByTheFamilyTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    typeNotRequiredByTheFamilyTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "not required by the family")
        }
    }
#endif
