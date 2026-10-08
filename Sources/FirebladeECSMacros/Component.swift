//
//  Component.swift
//  FirebladeECSMacros
//
//  Created by Christian Treffs on 08.10.26.
//

/// Turns a final class into a component and implements component protocols from its stored properties.
///
/// ```swift
/// @Component
/// final class Velocity: @unchecked Sendable {
///     var linear: Double = 0
///     var target: Entity?
/// }
/// ```
///
/// The macro implements
/// - ``RegistrableComponent`` (always). Declare `static let componentTypeName` to override the stable type name.
/// - ``CloneableComponent``: copies every stored property through ``ComponentCloneContext``,
///   remapping entity references.
/// - ``SerializableComponent``: encodes every stored property except `@ComponentIgnored` ones and
///   `let` constants with an initial value. Serialized properties require an explicit type annotation.
/// - ``InspectableComponent``: lists every stored property except `@ComponentIgnored` ones.
/// - ``DefaultInitializable``: generates `init()` if every stored property has a default value.
///
/// Members you declare yourself are not generated. Declaring any of `CodingKeys`, `init(from:)`
/// or `encode(to:)` leaves serialization entirely to you.
///
/// The generated initializers are designated initializers, so the class no longer receives an
/// implicit `init()`; keep ``ComponentMacroFeatures/defaultInit`` enabled or declare initializers.
/// - Parameter excluding: Features not to implement, e.g. `.serializable` for runtime-only components.
@attached(
    member,
    names: named(init(cloning:context:)), named(clone(context:)), named(init), named(init(from:)),
    named(encode(to:)), named(CodingKeys), named(componentProperties)
)
@attached(
    extension,
    conformances: RegistrableComponent, CloneableComponent, SerializableComponent, InspectableComponent, DefaultInitializable
)
public macro Component(excluding: ComponentMacroFeatures = []) = #externalMacro(module: "FirebladeECSMacrosImpl", type: "ComponentMacro")

/// Excludes a stored property of a ``Component(excluding:)`` class from serialization and inspection.
///
/// Ignored properties are still cloned and must have a default value.
@attached(peer)
public macro ComponentIgnored() = #externalMacro(module: "FirebladeECSMacrosImpl", type: "ComponentIgnoredMacro")
