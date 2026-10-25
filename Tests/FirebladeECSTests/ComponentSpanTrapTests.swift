//
//  ComponentSpanTrapTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

// Misuse of the span APIs traps with a message instead of leaving a dangling or aliased write. Each case runs in a child
// process; exit tests are unavailable on iOS, tvOS, watchOS and WebAssembly. Exit test bodies cannot capture context,
// so each trap is a free function.
#if os(macOS) || os(Linux) || os(Windows)

    private func makeNexus(_ storage: Nexus.StorageKind) -> Nexus {
        let nexus = Nexus(storage: storage)
        for number in 0 ..< 3 {
            nexus.createEntity(with: Comp1(number), Comp2(number))
        }
        return nexus
    }

    // Release (-O) builds trap without printing the precondition message, so only check it in debug builds.
    private func expectTrapMessage(_ result: ExitTest.Result?, _ message: String) {
        #if DEBUG
            let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
            #expect(stderr.contains(message))
        #endif
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func creatingAnEntityInAWriteSpanTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        nexus.componentSpan(writing: Comp1.self) { _ in nexus.createEntity(with: Comp3(1)) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func creatingAnEntityInAReadSpanTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        nexus.componentSpan(reading: Comp1.self) { _ in nexus.createEntity() }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func removingAComponentInAReadSpanTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let entity = nexus.family(requires: Comp2.self).entities.first { _ in true }
        nexus.componentSpan(reading: Comp1.self) { _ in entity?.remove(Comp2.self) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func nestedWriteSpanTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        nexus.componentSpan(writing: Comp1.self) { _ in
            nexus.componentSpan(writing: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func readSpanOfAWrittenTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        nexus.componentSpan(writing: Comp1.self) { _ in
            nexus.componentSpan(reading: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func writeSpanOfAReadTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        nexus.componentSpan(reading: Comp1.self) { _ in
            nexus.componentSpan(writing: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func readingAWrittenTypeThroughAnEntityTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let entity = nexus.family(requires: Comp1.self).entities.first { _ in true }
        nexus.componentSpan(writing: Comp1.self) { _ in _ = entity?.get(Comp1.self) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func modifyingAReadTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let entity = nexus.family(requires: Comp1.self).entities.first { _ in true }
        nexus.componentSpan(reading: Comp1.self) { _ in entity?.modify(Comp1.self) { $0.value = 1 } }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanReadingAndWritingTheSameTypeTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp1.self) { _, _ in }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanStructuralChangeTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { _, _ in nexus.createEntity() }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanTypeNotRequiredTrapsBody(_ storage: Nexus.StorageKind) {
        let nexus = makeNexus(storage)
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp3.self) { _ in }
    }

    @Suite struct ComponentSpanTrapTests {
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func creatingAnEntityInAWriteSpanTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityInAWriteSpanTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityInAWriteSpanTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func creatingAnEntityInAReadSpanTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityInAReadSpanTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    creatingAnEntityInAReadSpanTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func removingAComponentInAReadSpanTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    removingAComponentInAReadSpanTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    removingAComponentInAReadSpanTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func nestedWriteSpanTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedWriteSpanTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    nestedWriteSpanTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "nested write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func readSpanOfAWrittenTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readSpanOfAWrittenTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readSpanOfAWrittenTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func writeSpanOfAReadTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    writeSpanOfAReadTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    writeSpanOfAReadTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a read span")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func readingAWrittenTypeThroughAnEntityTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAWrittenTypeThroughAnEntityTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    readingAWrittenTypeThroughAnEntityTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func modifyingAReadTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    modifyingAReadTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    modifyingAReadTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "during a read span")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func familySpanReadingAndWritingTheSameTypeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanReadingAndWritingTheSameTypeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanReadingAndWritingTheSameTypeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func familySpanStructuralChangeTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanStructuralChangeTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanStructuralChangeTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test(arguments: Nexus.StorageKind.allCases) func familySpanTypeNotRequiredTraps(_ storage: Nexus.StorageKind) async {
            let result: ExitTest.Result?
            switch storage {
            case .sparseSet:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanTypeNotRequiredTrapsBody(.sparseSet)
                }
            case .archetype:
                result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                    familySpanTypeNotRequiredTrapsBody(.archetype)
                }
            }
            expectTrapMessage(result, "not required by the family")
        }
    }

#endif
