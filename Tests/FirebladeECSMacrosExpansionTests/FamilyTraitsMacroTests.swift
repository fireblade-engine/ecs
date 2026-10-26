//
//  FamilyTraitsMacroTests.swift
//  FirebladeECSMacrosExpansionTests
//
//  Created by Christian Treffs on 25.10.26.
//

// Must match `macroHostPlatforms` in Package.swift. `canImport` is unreliable here: Xcode may build
// FirebladeECSMacrosSupport for iOS while the swift-syntax test support stays unavailable there.
#if os(macOS) || os(Linux) || os(Windows)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite struct FamilyTraitsMacroTests {
    @Test func expandsReadingWritingAndExcluding() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
            struct Movers {}
            """,
            expandedSource: """
            struct Movers {

                typealias Bound = FirebladeECS.Family<Velocity, Position>

                static let traits = FirebladeECS.FamilyTraitSet(requiresAll: [Velocity.self, Position.self], excludesAll: [Frozen.self])

                static let readComponents: Set<FirebladeECS.ComponentIdentifier> = [Velocity.identifier]

                static let writeComponents: Set<FirebladeECS.ComponentIdentifier> = [Position.identifier]

                static let familyIndex = FirebladeECS.Nexus.familyIndex(of: Movers.self)

                let family: FirebladeECS.Family<Velocity, Position>

                static func makeFamily(in nexus: FirebladeECS.Nexus) -> FirebladeECS.Family<Velocity, Position> {
                    FirebladeECS.Family<Velocity, Position>(nexus: nexus, requiresAll: Velocity.self, Position.self, excludesAll: [Frozen.self])
                }

                init(in nexus: FirebladeECS.Nexus) {
                    family = nexus.family(for: Movers.self)
                }

                /// Calls `body` with the read components and the in-place changed components of every member.
                ///
                /// Forwards to `Family.forEach(reading:writing:)`.
                func forEach(_ body: (Velocity, inout Position) throws -> Void) rethrows {
                    try family.forEach(reading: Velocity.self, writing: Position.self, body)
                }
            }

            extension Movers: FirebladeECS.FamilyTraitsProviding {
            }
            """
        )
    }

    @Test func expandsPublicReadOnlyFamily() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Position.self, Velocity.self)
            public struct Observers {}
            """,
            expandedSource: """
            public struct Observers {

                public typealias Bound = FirebladeECS.Family<Position, Velocity>

                public static let traits = FirebladeECS.FamilyTraitSet(requiresAll: [Position.self, Velocity.self], excludesAll: [])

                public static let readComponents: Set<FirebladeECS.ComponentIdentifier> = [Position.identifier, Velocity.identifier]

                public static let writeComponents: Set<FirebladeECS.ComponentIdentifier> = []

                public static let familyIndex = FirebladeECS.Nexus.familyIndex(of: Observers.self)

                public let family: FirebladeECS.Family<Position, Velocity>

                public static func makeFamily(in nexus: FirebladeECS.Nexus) -> FirebladeECS.Family<Position, Velocity> {
                    FirebladeECS.Family<Position, Velocity>(nexus: nexus, requiresAll: Position.self, Velocity.self, excludesAll: [])
                }

                public init(in nexus: FirebladeECS.Nexus) {
                    family = nexus.family(for: Observers.self)
                }

                /// Calls `body` with the read components and the in-place changed components of every member.
                ///
                /// Forwards to `Family.forEach(reading:writing:)`.
                public func forEach(_ body: (Position, Velocity) throws -> Void) rethrows {
                    try family.forEach(reading: Position.self, Velocity.self, body)
                }
            }

            extension Observers: FirebladeECS.FamilyTraitsProviding {
            }
            """
        )
    }

    @Test func expandsWriteOnlyFamily() {
        assertComponentExpansion(
            """
            @FamilyTraits(writing: Position.self, Velocity.self)
            struct Resetters {}
            """,
            expandedSource: """
            struct Resetters {

                typealias Bound = FirebladeECS.Family<Position, Velocity>

                static let traits = FirebladeECS.FamilyTraitSet(requiresAll: [Position.self, Velocity.self], excludesAll: [])

                static let readComponents: Set<FirebladeECS.ComponentIdentifier> = []

                static let writeComponents: Set<FirebladeECS.ComponentIdentifier> = [Position.identifier, Velocity.identifier]

                static let familyIndex = FirebladeECS.Nexus.familyIndex(of: Resetters.self)

                let family: FirebladeECS.Family<Position, Velocity>

                static func makeFamily(in nexus: FirebladeECS.Nexus) -> FirebladeECS.Family<Position, Velocity> {
                    FirebladeECS.Family<Position, Velocity>(nexus: nexus, requiresAll: Position.self, Velocity.self, excludesAll: [])
                }

                init(in nexus: FirebladeECS.Nexus) {
                    family = nexus.family(for: Resetters.self)
                }

                /// Calls `body` with the read components and the in-place changed components of every member.
                ///
                /// Forwards to `Family.forEach(reading:writing:)`.
                func forEach(_ body: (inout Position, inout Velocity) throws -> Void) rethrows {
                    try family.forEach(writing: Position.self, Velocity.self, body)
                }
            }

            extension Resetters: FirebladeECS.FamilyTraitsProviding {
            }
            """
        )
    }

    @Test func expandsPackFallbackAboveFourReads() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: A.self, B.self, C.self, D.self, E.self, writing: X.self, Y.self)
            struct Wide {}
            """,
            expandedSource: """
            struct Wide {

                typealias Bound = FirebladeECS.Family<A, B, C, D, E, X, Y>

                static let traits = FirebladeECS.FamilyTraitSet(requiresAll: [A.self, B.self, C.self, D.self, E.self, X.self, Y.self], excludesAll: [])

                static let readComponents: Set<FirebladeECS.ComponentIdentifier> = [A.identifier, B.identifier, C.identifier, D.identifier, E.identifier]

                static let writeComponents: Set<FirebladeECS.ComponentIdentifier> = [X.identifier, Y.identifier]

                static let familyIndex = FirebladeECS.Nexus.familyIndex(of: Wide.self)

                let family: FirebladeECS.Family<A, B, C, D, E, X, Y>

                static func makeFamily(in nexus: FirebladeECS.Nexus) -> FirebladeECS.Family<A, B, C, D, E, X, Y> {
                    FirebladeECS.Family<A, B, C, D, E, X, Y>(nexus: nexus, requiresAll: A.self, B.self, C.self, D.self, E.self, X.self, Y.self, excludesAll: [])
                }

                init(in nexus: FirebladeECS.Nexus) {
                    family = nexus.family(for: Wide.self)
                }

                /// Calls `body` with the read components and the in-place changed components of every member.
                ///
                /// Forwards to `Family.forEach(reading:writing:)`.
                func forEach(_ body: (A, B, C, D, E, inout X, inout Y) throws -> Void) rethrows {
                    try family.forEach(reading: A.self, B.self, C.self, D.self, E.self, writing: X.self, Y.self) { (written: inout (X, Y), r0: A, r1: B, r2: C, r3: D, r4: E) in
                        try body(r0, r1, r2, r3, r4, &written.0, &written.1)
                    }
                }
            }

            extension Wide: FirebladeECS.FamilyTraitsProviding {
            }
            """
        )
    }

    @Test func rejectsClass() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Velocity.self)
            final class Movers {}
            """,
            expandedSource: """
            final class Movers {}
            """,
            diagnostics: [DiagnosticSpec(message: "@FamilyTraits can only be applied to a struct", line: 1, column: 1)]
        )
    }

    @Test func rejectsEmptyDeclaration() {
        assertComponentExpansion(
            """
            @FamilyTraits(excluding: Frozen.self)
            struct Nothing {}
            """,
            expandedSource: """
            struct Nothing {}
            """,
            diagnostics: [DiagnosticSpec(message: "@FamilyTraits requires at least one type in 'reading:' or 'writing:'", line: 1, column: 1)]
        )
    }

    @Test func rejectsReadAndWrittenType() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Position.self, writing: Position.self)
            struct Both {}
            """,
            expandedSource: """
            struct Both {}
            """,
            diagnostics: [DiagnosticSpec(message: "a component type can not be both read and written; list it in 'writing:' only", line: 1, column: 48)]
        )
    }

    @Test func rejectsRequiredAndExcludedType() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Position.self, excluding: Position.self)
            struct Contradiction {}
            """,
            expandedSource: """
            struct Contradiction {}
            """,
            diagnostics: [DiagnosticSpec(message: "a component type can not be both required and excluded", line: 1, column: 50)]
        )
    }

    @Test func rejectsDuplicateType() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Position.self, Position.self)
            struct Twice {}
            """,
            expandedSource: """
            struct Twice {}
            """,
            diagnostics: [DiagnosticSpec(message: "component type is listed more than once", line: 1, column: 39)]
        )
    }

    @Test func rejectsNonMetatypeArguments() {
        assertComponentExpansion(
            """
            @FamilyTraits(reading: Position)
            struct NotMetatype {}
            """,
            expandedSource: """
            struct NotMetatype {}
            """,
            diagnostics: [DiagnosticSpec(message: "@FamilyTraits expects component metatypes such as 'Position.self'", line: 1, column: 24)]
        )
    }
}
#endif
