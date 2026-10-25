//
//  ComponentMacroTests.swift
//  FirebladeECSMacrosExpansionTests
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
            public struct Velocity {
                public var linear: Double = 0
                public var target: EntityIdentifier?
            }
            """,
            expandedSource: """
            public struct Velocity {
                public var linear: Double = 0
                public var target: EntityIdentifier?

                public init() {
                }
            }

            extension Velocity: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent, FirebladeECS.InspectableComponent, FirebladeECS.DefaultInitializable {
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
                    self.target = try container.decodeIfPresent(EntityIdentifier.self, forKey: .target)
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
            struct Mixed {
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
            struct Mixed {
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
            }

            extension Mixed: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.InspectableComponent {
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
            """
        )
    }

    @Test func serializesOptionalsAndSkipsIgnoredAndConstants() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .inspectable, .defaultInit])
            package struct Health {
                let maximum = 100
                var current: Int = 100
                var shield: Int!
                var regeneration: Optional<Double> = nil
                @ComponentIgnored var onChange: (() -> Void)? = nil
            }
            """,
            expandedSource: """
            package struct Health {
                let maximum = 100
                var current: Int = 100
                var shield: Int!
                var regeneration: Optional<Double> = nil
                var onChange: (() -> Void)? = nil
            }

            extension Health: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.SerializableComponent {
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
            """
        )
    }

    @Test func emptyComponent() {
        assertComponentExpansion(
            """
            @Component
            struct Tag {
            }
            """,
            expandedSource: """
            struct Tag {
            }

            extension Tag: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent, FirebladeECS.InspectableComponent, FirebladeECS.DefaultInitializable {
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
            struct Custom: Codable {
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
            struct Custom: Codable {
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

            extension Custom: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent {
            }
            """
        )
    }

    @Test func declaredDefaultInitAddsConformanceOnly() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .serializable, .inspectable])
            struct Counter {
                var count: Int

                init() {
                    count = 0
                }
            }
            """,
            expandedSource: """
            struct Counter {
                var count: Int

                init() {
                    count = 0
                }
            }

            extension Counter: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.DefaultInitializable {
            }
            """
        )
    }
}

@Suite struct ComponentMacroDiagnosticTests {
    @Test func rejectsClass() {
        assertComponentExpansion(
            """
            @Component
            final class Reference {
            }
            """,
            expandedSource: """
            final class Reference {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Component requires a value type (struct or enum); classes are not supported", line: 1, column: 1)
            ]
        )
    }

    @Test func acceptsEnum() {
        assertComponentExpansion(
            """
            @Component
            enum Phase: Codable {
                case idle
                case running(Int)
            }
            """,
            expandedSource: """
            enum Phase: Codable {
                case idle
                case running(Int)
            }

            extension Phase: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.CloneableComponent, FirebladeECS.SerializableComponent, FirebladeECS.InspectableComponent {
                init(cloning other: Phase, context: FirebladeECS.ComponentCloneContext) {
                    self = other
                }
                func clone(context: FirebladeECS.ComponentCloneContext) -> Phase {
                    Phase(cloning: self, context: context)
                }
                static var componentProperties: [FirebladeECS.ComponentProperty<Phase>] {
                    []
                }
            }
            """
        )
    }

    @Test func reportsUnsupportedProperties() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .inspectable, .defaultInit, .unknown])
            struct Broken {
                lazy var expensive: Int = 0
                var (a, b): (Int, Int) = (0, 0)
                var inferred = 1
                @ComponentIgnored var transient: Int
            }
            """,
            expandedSource: """
            struct Broken {
                lazy var expensive: Int = 0
                var (a, b): (Int, Int) = (0, 0)
                var inferred = 1
                var transient: Int
            }

            extension Broken: FirebladeECS.Component, FirebladeECS.RegistrableComponent {
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
            struct Untyped {
                var inferred = 1
            }
            """,
            expandedSource: """
            struct Untyped {
                var inferred = 1
            }

            extension Untyped: FirebladeECS.Component, FirebladeECS.RegistrableComponent, FirebladeECS.DefaultInitializable {
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

@Suite struct ComponentMacroStoredEntityTests {
    @Test func suggestsEntityIdentifier() {
        assertComponentExpansion(
            """
            @Component(excluding: [.cloneable, .serializable, .inspectable, .defaultInit])
            struct Links {
                var parent: Entity?
                var children: [Entity]
                var group: Set<Entity>
                var named: [String: Entity]
                var qualified: FirebladeECS.Entity!
                var fine: EntityIdentifier?
                var alias: EntityAlias
                var x, y: Entity
            }
            """,
            expandedSource: """
            struct Links {
                var parent: Entity?
                var children: [Entity]
                var group: Set<Entity>
                var named: [String: Entity]
                var qualified: FirebladeECS.Entity!
                var fine: EntityIdentifier?
                var alias: EntityAlias
                var x, y: Entity
            }

            extension Links: FirebladeECS.Component, FirebladeECS.RegistrableComponent {
            }
            """,
            diagnostics: [
                entityDiagnostic(line: 3, column: 17),
                entityDiagnostic(line: 4, column: 20),
                entityDiagnostic(line: 5, column: 20),
                entityDiagnostic(line: 6, column: 25),
                entityDiagnostic(line: 7, column: 33),
                entityDiagnostic(line: 10, column: 15)
            ]
        )
    }

    private func entityDiagnostic(line: Int, column: Int) -> DiagnosticSpec {
        DiagnosticSpec(
            message: "a component must not store an 'Entity'; store an 'EntityIdentifier', which stays valid when the component is copied, cloned or saved",
            line: line,
            column: column,
            fixIts: [FixItSpec(message: "replace 'Entity' with 'EntityIdentifier'")]
        )
    }
}
#endif
