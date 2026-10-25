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

    private func family() -> (Nexus, Family<Comp1, Comp2>) {
        let nexus = Nexus()
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

    private func creatingAnEntityTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp1.self, writing: Comp2.self) { _, _ in nexus.createEntity() }
    }

    private func addingAComponentTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        let entity = nexus.createEntity()
        family.forEach(reading: Comp1.self) { _ in entity.set(Comp4(1)) }
    }

    private func readingAWrittenTypeThroughTheNexusTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp2.self) { _ in
            _ = family.entities.first { _ in true }?.get(Comp2.self)
        }
    }

    private func readingAndWritingTheSameTypeTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp1.self, writing: Comp1.self) { _, _ in }
    }

    private func writingTheSameTypeTwiceTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self, Comp1.self) { _, _ in }
    }

    private func nestedWriteOfTheSameTypeTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self) { _ in
            family.forEach(writing: Comp1.self) { _ in }
        }
    }

    private func nestedReadOfAWrittenTypeTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(writing: Comp1.self) { _ in
            family.forEach(reading: Comp1.self) { _ in }
        }
    }

    private func typeNotRequiredByTheFamilyTrapsBody() {
        let (nexus, family) = family()
        defer { withExtendedLifetime(nexus) {} }
        family.forEach(reading: Comp3.self) { _ in }
    }

    @Suite struct FamilyReadWriteTrapTests {
        @Test func creatingAnEntityTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                creatingAnEntityTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @Test func addingAComponentTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                addingAComponentTrapsBody()
            }
            expectTrapMessage(result, "structural change")
        }

        @Test func readingAWrittenTypeThroughTheNexusTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                readingAWrittenTypeThroughTheNexusTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test func readingAndWritingTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                readingAndWritingTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test func writingTheSameTypeTwiceTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                writingTheSameTypeTwiceTrapsBody()
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test func nestedWriteOfTheSameTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                nestedWriteOfTheSameTypeTrapsBody()
            }
            expectTrapMessage(result, "nested write access")
        }

        @Test func nestedReadOfAWrittenTypeTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                nestedReadOfAWrittenTypeTrapsBody()
            }
            expectTrapMessage(result, "during a write access")
        }

        @Test func typeNotRequiredByTheFamilyTraps() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                typeNotRequiredByTheFamilyTrapsBody()
            }
            expectTrapMessage(result, "not required by the family")
        }
    }
#endif
