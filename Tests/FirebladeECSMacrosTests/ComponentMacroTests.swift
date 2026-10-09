//
//  ComponentMacroTests.swift
//  FirebladeECSMacrosTests
//
//  Created by Christian Treffs on 08.10.26.
//

// Must match `macroHostPlatforms` in Package.swift. `canImport` is unreliable here: Xcode may build
// FirebladeECSMacrosSupport for iOS while the swift-syntax test support stays unavailable there.
#if os(macOS) || os(Linux) || os(Windows)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@Suite struct ComponentMacroTests {
    @Test func expandsAllFeatures() {
        assertComponentExpansion(
            """
            @Component
            public final class Velocity {
                public var linear: Double = 0
                public var target: Entity?
            }
            """,
            expandedSource: """
            public final class Velocity {
                public var linear: Double = 0
                public var target: Entity?

                public init(cloning other: Velocity, context: FirebladeECS.ComponentCloneContext) {
                    self.linear = context.clone(other.linear)
                    self.target = context.clone(other.target)
                }

                public func clone(context: FirebladeECS.ComponentCloneContext) -> Velocity {
                    Velocity(cloning: self, context: context)
                }

                private enum CodingKeys: String, Swift.CodingKey {
                    case linear
                    case target
                }

                public init(from decoder: any Swift.Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.linear = try container.decode(Double.self, forKey: .linear)
                    self.target = try container.decodeIfPresent(Entity.self, forKey: .target)
                }

                public func encode(to encoder: any Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.linear, forKey: .linear)
                    try container.encodeIfPresent(self.target, forKey: .target)
                }

                public static var componentProperties: [FirebladeECS.ComponentProperty<Velocity>] {
                    [
                        FirebladeECS.ComponentProperty(name: "linear", keyPath: \\Velocity.linear),
                        FirebladeECS.ComponentProperty(name: "target", keyPath: \\Velocity.target)
                    ]
                }

                public init() {
                }
            }

            extension Velocity: FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent, FirebladeECS.InspectableComponent, FirebladeECS.DefaultInitializable {
            }
            """
        )
    }
}

@Suite struct ComponentMacroPropertyTests {
    @Test func filtersPropertyKinds() {
        assertComponentExpansion(
            """
            @Component(excluding: .serializable)
            final class Mixed {
                static var shared = 0
                let kind = "mixed"
                let id: Int
                var observed: Int = 0 {
                    didSet {}
                }
                var computed: Int { id * 2 }
                var x, y: Float
                var wrapped: Optional<Int>
                @ComponentIgnored var cache: [Int] = []

                init(id: Int) {
                    self.id = id
                    x = 0
                    y = 0
                }
            }
            """,
            expandedSource: """
            final class Mixed {
                static var shared = 0
                let kind = "mixed"
                let id: Int
                var observed: Int = 0 {
                    didSet {}
                }
                var computed: Int { id * 2 }
                var x, y: Float
                var wrapped: Optional<Int>
                var cache: [Int] = []

                init(id: Int) {
                    self.id = id
                    x = 0
                    y = 0
                }

                init(cloning other: Mixed, context: FirebladeECS.ComponentCloneContext) {
                    self.id = context.clone(other.id)
                    self.observed = context.clone(other.observed)
                    self.x = context.clone(other.x)
                    self.y = context.clone(other.y)
                    self.wrapped = context.clone(other.wrapped)
                    self.cache = context.clone(other.cache)
                }

                func clone(context: FirebladeECS.ComponentCloneContext) -> Mixed {
                    Mixed(cloning: self, context: context)
                }

                static var componentProperties: [FirebladeECS.ComponentProperty<Mixed>] {
                    [
                        FirebladeECS.ComponentProperty(name: "kind", keyPath: \\Mixed.kind),
                        FirebladeECS.ComponentProperty(name: "id", keyPath: \\Mixed.id),
                        FirebladeECS.ComponentProperty(name: "observed", keyPath: \\Mixed.observed),
                        FirebladeECS.ComponentProperty(name: "x", keyPath: \\Mixed.x),
                        FirebladeECS.ComponentProperty(name: "y", keyPath: \\Mixed.y),
                        FirebladeECS.ComponentProperty(name: "wrapped", keyPath: \\Mixed.wrapped)
                    ]
                }
            }

            extension Mixed: FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.InspectableComponent {
            }
            """
        )
    }

    @Test func serializesOptionalsAndSkipsIgnoredAndConstants() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .inspectable, .defaultInit])
            package final class Health {
                let maximum = 100
                var current: Int = 100
                var shield: Int!
                var regeneration: Optional<Double> = nil
                @ComponentIgnored var onChange: (() -> Void)? = nil
            }
            """,
            expandedSource: """
            package final class Health {
                let maximum = 100
                var current: Int = 100
                var shield: Int!
                var regeneration: Optional<Double> = nil
                var onChange: (() -> Void)? = nil

                private enum CodingKeys: String, Swift.CodingKey {
                    case current
                    case shield
                    case regeneration
                }

                package init(from decoder: any Swift.Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.current = try container.decode(Int.self, forKey: .current)
                    self.shield = try container.decodeIfPresent(Int.self, forKey: .shield)
                    self.regeneration = try container.decodeIfPresent(Double.self, forKey: .regeneration)
                }

                package func encode(to encoder: any Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(self.current, forKey: .current)
                    try container.encodeIfPresent(self.shield, forKey: .shield)
                    try container.encodeIfPresent(self.regeneration, forKey: .regeneration)
                }
            }

            extension Health: FirebladeECS.RegistrableComponent, FirebladeECS.SerializableComponent {
            }
            """
        )
    }

    @Test func emptyComponent() {
        assertComponentExpansion(
            """
            @Component
            final class Tag {
            }
            """,
            expandedSource: """
            final class Tag {

                init(cloning other: Tag, context: FirebladeECS.ComponentCloneContext) {
                }

                func clone(context: FirebladeECS.ComponentCloneContext) -> Tag {
                    Tag(cloning: self, context: context)
                }

                init(from _: any Swift.Decoder) throws {
                }

                func encode(to _: any Swift.Encoder) throws {
                }

                static var componentProperties: [FirebladeECS.ComponentProperty<Tag>] {
                    []
                }

                init() {
                }
            }

            extension Tag: FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent, FirebladeECS.InspectableComponent, FirebladeECS.DefaultInitializable {
            }
            """
        )
    }
}

@Suite struct ComponentMacroDeclaredMemberTests {
    @Test func respectsDeclaredMembersAndMissingDefaults() {
        assertComponentExpansion(
            """
            @Component(excluding: .inspectable)
            final class Custom: Codable {
                var value: Int

                init(value: Int) {
                    self.value = value
                }

                enum CodingKeys: String, CodingKey {
                    case value = "v"
                }

                func clone(context: ComponentCloneContext) -> Custom {
                    Custom(value: value)
                }
            }
            """,
            expandedSource: """
            final class Custom: Codable {
                var value: Int

                init(value: Int) {
                    self.value = value
                }

                enum CodingKeys: String, CodingKey {
                    case value = "v"
                }

                func clone(context: ComponentCloneContext) -> Custom {
                    Custom(value: value)
                }
            }

            extension Custom: FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent {
            }
            """
        )
    }

    @Test func declaredDefaultInitAddsConformanceOnly() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .serializable, .inspectable])
            final class Counter {
                var count: Int

                init() {
                    count = 0
                }
            }
            """,
            expandedSource: """
            final class Counter {
                var count: Int

                init() {
                    count = 0
                }
            }

            extension Counter: FirebladeECS.RegistrableComponent, FirebladeECS.DefaultInitializable {
            }
            """
        )
    }
}

@Suite struct ComponentMacroDiagnosticTests {
    @Test func requiresFinalClass() {
        assertComponentExpansion(
            """
            @Component
            class Open {
            }
            @Component
            struct Value {
            }
            """,
            expandedSource: """
            class Open {
            }
            struct Value {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Component can only be applied to a final class", line: 1, column: 1),
                DiagnosticSpec(message: "@Component can only be applied to a final class", line: 4, column: 1)
            ]
        )
    }

    @Test func reportsUnsupportedProperties() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .inspectable, .defaultInit, .unknown])
            final class Broken {
                lazy var expensive: Int = 0
                var (a, b): (Int, Int) = (0, 0)
                var inferred = 1
                @ComponentIgnored var transient: Int
            }
            """,
            expandedSource: """
            final class Broken {
                lazy var expensive: Int = 0
                var (a, b): (Int, Int) = (0, 0)
                var inferred = 1
                var transient: Int
            }

            extension Broken: FirebladeECS.RegistrableComponent {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'excluding:' expects a ComponentMacroFeatures literal such as '.serializable' or '[.serializable, .inspectable]'",
                    line: 1,
                    column: 64
                ),
                DiagnosticSpec(message: "@Component does not support lazy properties", line: 3, column: 14),
                DiagnosticSpec(message: "@Component only supports stored properties bound to a single identifier", line: 4, column: 9),
                DiagnosticSpec(message: "@ComponentIgnored property requires a default value", line: 6, column: 27)
            ]
        )
    }

    @Test func serializedPropertyRequiresTypeAnnotation() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .inspectable])
            final class Untyped {
                var inferred = 1
            }
            """,
            expandedSource: """
            final class Untyped {
                var inferred = 1

                init() {
                }
            }

            extension Untyped: FirebladeECS.RegistrableComponent, FirebladeECS.DefaultInitializable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "serialized property requires an explicit type annotation; add one, mark the property @ComponentIgnored or use @Component(excluding: .serializable)",
                    line: 3,
                    column: 9
                )
            ]
        )
    }
}
#endif
