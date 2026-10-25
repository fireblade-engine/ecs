//
//  ComponentClassTrapTests.swift
//  FirebladeECSTests
//
//  Created by Christian Treffs on 25.10.26.
//

@testable import FirebladeECS
import Testing

// A hand-written class conformance can not be rejected at compile time; the registry asserts it when it creates
// the storage of the type. The assertion is compiled out of release builds, so these tests exist in debug builds only.
// Each case runs in a child process; exit tests are unavailable on iOS, tvOS, watchOS and WebAssembly.
#if DEBUG && (os(macOS) || os(Linux) || os(Windows))

    private final class ClassComponent: Component, @unchecked Sendable {}

    @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
    private func addingAClassComponentAssertsBody() {
        let nexus = Nexus()
        nexus.createEntity(with: ClassComponent())
    }

    @Suite struct ComponentClassTrapTests {
        @available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
        @Test func addingAClassComponentAsserts() async {
            let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
                addingAClassComponentAssertsBody()
            }
            let stderr = String(decoding: result?.standardErrorContent ?? [], as: UTF8.self)
            #expect(stderr.contains("components must be structs or enums"))
        }
    }

#endif
