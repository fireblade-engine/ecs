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

    private func makeNexus() -> Nexus {
        let nexus = Nexus()
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
    private func creatingAnEntityInAWriteSpanTrapsBody() {
        let nexus = makeNexus()
        nexus.componentSpan(writing: Comp1.self) { _ in nexus.createEntity(with: Comp3(1)) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func creatingAnEntityInAReadSpanTrapsBody() {
        let nexus = makeNexus()
        nexus.componentSpan(reading: Comp1.self) { _ in nexus.createEntity() }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func removingAComponentInAReadSpanTrapsBody() {
        let nexus = makeNexus()
        let entity = nexus.family(requires: Comp2.self).entities.first { _ in true }
        nexus.componentSpan(reading: Comp1.self) { _ in entity?.remove(Comp2.self) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func nestedWriteSpanTrapsBody() {
        let nexus = makeNexus()
        nexus.componentSpan(writing: Comp1.self) { _ in
            nexus.componentSpan(writing: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func readSpanOfAWrittenTypeTrapsBody() {
        let nexus = makeNexus()
        nexus.componentSpan(writing: Comp1.self) { _ in
            nexus.componentSpan(reading: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func writeSpanOfAReadTypeTrapsBody() {
        let nexus = makeNexus()
        nexus.componentSpan(reading: Comp1.self) { _ in
            nexus.componentSpan(writing: Comp1.self) { _ in }
        }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func readingAWrittenTypeThroughAnEntityTrapsBody() {
        let nexus = makeNexus()
        let entity = nexus.family(requires: Comp1.self).entities.first { _ in true }
        nexus.componentSpan(writing: Comp1.self) { _ in _ = entity?.get(Comp1.self) }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func modifyingAReadTypeTrapsBody() {
        let nexus = makeNexus()
        let entity = nexus.family(requires: Comp1.self).entities.first { _ in true }
        nexus.componentSpan(reading: Comp1.self) { _ in entity?.modify(Comp1.self) { $0.value = 1 } }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanReadingAndWritingTheSameTypeTrapsBody() {
        let nexus = makeNexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp1.self) { _, _ in }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanStructuralChangeTrapsBody() {
        let nexus = makeNexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp1.self, writing: Comp2.self) { _, _ in nexus.createEntity() }
    }

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func familySpanTypeNotRequiredTrapsBody() {
        let nexus = makeNexus()
        let family = nexus.family(requiresAll: Comp1.self, Comp2.self)
        family.forEachComponentSpan(reading: Comp3.self) { _ in }
    }

    @Suite struct ComponentSpanTrapTests {
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func creatingAnEntityInAWriteSpanTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                creatingAnEntityInAWriteSpanTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func creatingAnEntityInAReadSpanTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                creatingAnEntityInAReadSpanTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func removingAComponentInAReadSpanTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                removingAComponentInAReadSpanTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func nestedWriteSpanTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                nestedWriteSpanTrapsBody()
            }
            expectTrapMessage(result, "nested write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func readSpanOfAWrittenTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                readSpanOfAWrittenTypeTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func writeSpanOfAReadTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                writeSpanOfAReadTypeTrapsBody()
            }
            expectTrapMessage(result, "during a read span")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func readingAWrittenTypeThroughAnEntityTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                readingAWrittenTypeThroughAnEntityTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func modifyingAReadTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                modifyingAReadTypeTrapsBody()
            }
            expectTrapMessage(result, "during a read span")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func familySpanReadingAndWritingTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                familySpanReadingAndWritingTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "write access")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func familySpanStructuralChangeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                familySpanStructuralChangeTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func familySpanTypeNotRequiredTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                familySpanTypeNotRequiredTrapsBody()
            }
            expectTrapMessage(result, "not required by the family")
        }
    }

#endif
