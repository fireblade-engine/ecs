//
//  Component.swift
//  FirebladeECSMacros
//
//  Created by Christian Treffs on 08.10.26.
//

/// Turns a struct or enum into a component and implements component protocols from its stored properties.
///
/// ```swift
/// @Component
/// struct Velocity {
///     var linear: Double = 0
///     var target: EntityIdentifier?
/// }
/// ```
///
/// Classes are rejected with a diagnostic: components are value types.
///
/// The macro implements
/// - ``RegistrableComponent`` (always). Declare `static let componentTypeName` to override the stable type name.
/// - ``CloneableComponent``: copies every stored property through ``ComponentCloneContext``,
///   remapping entity references. An enum is copied as a whole.
/// - ``SerializableComponent``: encodes every stored property except `@ComponentIgnored` ones and
///   `let` constants with an initial value. Serialized properties require an explicit type annotation.
///   An enum has to declare its own `Codable` conformance.
/// - ``InspectableComponent``: lists every stored property except `@ComponentIgnored` ones.
/// - ``DefaultInitializable``: for a struct with a default value for every stored property.
///
/// Members you declare yourself are not generated. Declaring any of `CodingKeys`, `init(from:)`
/// or `encode(to:)` leaves serialization entirely to you.
///
/// The macro also stores the type's ``Component/componentIndex`` in a `static let`, so typed lookups read a plain
/// static instead of taking the registry lock. Declare your own `componentIndex` to opt out.
///
/// The generated initializers live in an extension, so a struct keeps its memberwise initializer.
/// Only a `public` or `package` struct, or a struct that declares initializers, receives a generated `init()`
/// in its body, because the implicit one is internal and does not exist next to declared initializers.
/// - Parameter excluding: Features not to implement, e.g. `.serializable` for runtime-only components.
@attached(member, names: named(init), named(componentIndex))
@attached(
    extension,
    conformances: Component, RegistrableComponent, CloneableComponent, SerializableComponent, InspectableComponent,
    DefaultInitializable,
    names: named(init(cloning:context:)), named(clone(context:)), named(init(from:)),
    named(encode(to:)), named(CodingKeys), named(componentProperties)
)
public macro Component(excluding: ComponentMacroFeatures = []) = #externalMacro(module: "FirebladeECSMacrosImpl", type: "ComponentMacro")

/// Excludes a stored property of a ``Component(excluding:)`` class from serialization and inspection.
///
/// Ignored properties are still cloned and must have a default value.
@attached(peer)
public macro ComponentIgnored() = #externalMacro(module: "FirebladeECSMacrosImpl", type: "ComponentIgnoredMacro")
