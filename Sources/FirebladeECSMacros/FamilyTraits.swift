//
//  FamilyTraits.swift
//  FirebladeECSMacros
//
//  Created by Christian Treffs on 25.10.26.
//

/// Declares a struct as a family of entities and generates its ``FamilyTraitsProviding`` conformance.
///
/// ```swift
/// @FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
/// struct Movers {}
///
/// let movers = Movers(in: nexus)
/// movers.forEach { velocity, position in position.x += velocity.dx }
/// ```
///
/// The macro generates
/// - the `traits` (reading and writing types are required, excluded types must be absent) and the static
///   `readComponents` and `writeComponents` sets,
/// - a `family` property of the typed `Family` bound to the nexus, and `init(in:)`, a cache lookup,
/// - `forEach`, which takes the read components first, then the written ones as `inout`, and calls the
///   matching `Family/forEach(reading:writing:)` overload.
///
/// Reading and writing the same type, an empty declaration, arguments that are not metatypes and attaching
/// to anything but a struct are errors.
/// - Parameters:
///   - reading: Required component types the family only reads.
///   - writing: Required component types the family changes in place.
///   - excluding: Component types a member must not have.
@attached(
    member,
    names: named(Bound), named(traits), named(readComponents), named(writeComponents), named(familyIndex),
    named(family), named(makeFamily), named(init), named(forEach)
)
@attached(extension, conformances: FamilyTraitsProviding)
public macro FamilyTraits(
    reading: any Component.Type...,
    writing: any Component.Type...,
    excluding: any Component.Type...
) = #externalMacro(module: "FirebladeECSMacrosImpl", type: "FamilyTraitsMacro")
