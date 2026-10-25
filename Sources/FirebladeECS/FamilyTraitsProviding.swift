//
//  FamilyTraitsProviding.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

/// The members a family exposes independent of its component types.
///
/// ``Family`` conforms; ``FamilyTraitsProviding`` forwards to it.
public protocol FamilyProtocol {
    /// The sequence of member entities.
    associatedtype Entities: Sequence where Entities.Element == Entity

    /// The number of members.
    var count: Int { get }

    /// Whether the family has no members.
    var isEmpty: Bool { get }

    /// The member entities.
    var entities: Entities { get }

    /// Whether the entity is currently a member.
    func isMember(_ entity: Entity) -> Bool
}

extension Family: FamilyProtocol {}

/// A family declared as a type and bound to a nexus as a value.
///
/// Two roles, one type: `Movers.self` is the static declaration (its ``traits``, ``readComponents`` and
/// ``writeComponents`` are what a scheduler needs to know without a nexus), a `Movers(in: nexus)` value is that
/// family bound to one nexus. Binding is a cache lookup by ``familyIndex``, not a trait set hash, so create the
/// value once and keep it in the system.
/// Like ``Entity``, a bound family must not outlive its nexus.
///
/// Conform by hand, or let the `@FamilyTraits` macro write the conformance and a typed `forEach`:
/// ```swift
/// @FamilyTraits(reading: Velocity.self, writing: Position.self, excluding: Frozen.self)
/// struct Movers {}
///
/// let movers = Movers(in: nexus)
/// movers.forEach { velocity, position in position.x += velocity.dx }
/// ```
///
/// This is the pattern of a flecs query descriptor (a query bound to a world, with `in`/`inout` access per term) and of
/// Bevy's `Query<(&Velocity, &mut Position), Without<Frozen>>` (a system parameter whose read and write sets feed the scheduler).
public protocol FamilyTraitsProviding {
    /// The typed family that backs this declaration.
    associatedtype Bound: FamilyProtocol

    /// The required and excluded components.
    static var traits: FamilyTraitSet { get }

    /// The components the family only reads. Defaults to all required components.
    static var readComponents: Set<ComponentIdentifier> { get }

    /// The components the family changes in place. Defaults to none.
    static var writeComponents: Set<ComponentIdentifier> { get }

    /// The dense per-process index of this type, used to find the bound family of a nexus without hashing.
    ///
    /// The default assigns indices lazily, like ``Component/componentIndex``; the macro stores it in a static.
    static var familyIndex: Int { get }

    /// Creates the typed family in a nexus. ``Nexus/family(for:)`` calls it once per nexus and caches the result.
    static func makeFamily(in nexus: Nexus) -> Bound

    /// The family bound to the nexus this value was created with.
    var family: Bound { get }

    /// Binds the declaration to a nexus.
    init(in nexus: Nexus)
}

extension FamilyTraitsProviding {
    /// The number of members.
    @inlinable public var count: Int { family.count }

    /// Whether the family has no members.
    @inlinable public var isEmpty: Bool { family.isEmpty }

    /// The member entities.
    @inlinable public var entities: Bound.Entities { family.entities }

    /// Whether the entity is currently a member.
    @inlinable public func isMember(_ entity: Entity) -> Bool { family.isMember(entity) }

    /// All required components are read.
    public static var readComponents: Set<ComponentIdentifier> { traits.requiresAll }

    /// No component is written.
    public static var writeComponents: Set<ComponentIdentifier> { [] }

    /// A lazily assigned process-wide index.
    public static var familyIndex: Int {
        Nexus.FamilyIndexRegistry.shared.index(of: Self.self)
    }
}

extension Nexus {
    /// The family a ``FamilyTraitsProviding`` type declares, bound to this nexus.
    ///
    /// The family is created on first use and cached per type, later calls are an array lookup.
    /// - Parameter type: The declaring type.
    /// - Complexity: O(1) after the first call.
    public final func family<F: FamilyTraitsProviding>(for type: F.Type) -> F.Bound {
        let index = type.familyIndex
        if index < boundFamilies.count, let bound = boundFamilies[index] as? F.Bound {
            return bound
        }
        let bound = type.makeFamily(in: self)
        while boundFamilies.count <= index {
            boundFamilies.append(nil)
        }
        boundFamilies[index] = bound
        return bound
    }

    /// Assigns dense indices to ``FamilyTraitsProviding`` types, once per type and process.
    @usableFromInline
    final class FamilyIndexRegistry: @unchecked Sendable {
        @usableFromInline static let shared = FamilyIndexRegistry()

        private var indexByType: [ObjectIdentifier: Int] = [:]
        private let lock = Lock()

        private init() {}

        /// The index of a type; takes the next free index on first use.
        @usableFromInline
        func index(of type: any Any.Type) -> Int {
            lock.withLock {
                let key = ObjectIdentifier(type)
                if let existing = indexByType[key] {
                    return existing
                }
                let index = indexByType.count
                indexByType[key] = index
                return index
            }
        }
    }
}
