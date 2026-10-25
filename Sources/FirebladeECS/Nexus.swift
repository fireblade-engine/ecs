//
//  Nexus.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.17.
//

public final class Nexus {
    /// The storage of this nexus: entities, their component bitsets and the component arrays.
    @usableFromInline final let backend: Backend

    /// A map of family traits to the entities that match them.
    /// - Key: The family trait set (component types) that defines the family.
    /// - Value: A sparse set of entity identifiers that are members of this family.
    @usableFromInline final var familyMembersByTraits: [FamilyTraitSet: UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Index>]

    /// The membership predicates of the families, by their traits.
    @usableFromInline final var familyFiltersByTraits: [FamilyTraitSet: FamilyFilter]

    /// The families in creation order, so that membership updates visit them in a deterministic order without hashing.
    @usableFromInline final var familyList: ContiguousArray<(traits: FamilyTraitSet, filter: FamilyFilter)>

    /// The component types known to this nexus.
    ///
    /// Type knowledge outlives data: ``clear()`` does not remove registered types.
    final var componentRegistry: ComponentRegistry

    /// The entity identifier generator responsible for providing unique ids for entities during runtime.
    ///
    /// Provide a custom implementation prior to entity creation.
    /// Defaults to `DefaultEntityIdGenerator`.
    public final var entityIdGenerator: EntityIdentifierGenerator

    /// The coding strategy used to encode/decode entities from/into families.
    ///
    /// Provide a custom implementation prior to encoding/decoding.
    /// Defaults to `DefaultCodingStrategy`.
    public final var codingStrategy: CodingStrategy

    /// Indicates whether mutating an entity through a stale handle stops with an assertion failure in debug builds.
    ///
    /// Release builds only return `false` and report the problem to the delegate.
    final var assertsOnStaleHandles = true

    /// The delegate for handling nexus events.
    ///
    /// The nexus caches ``NexusEventDelegate/subscribedEvents`` when the delegate is assigned. Assign the delegate again
    /// after changing its subscription.
    public final weak var delegate: NexusEventDelegate? {
        didSet {
            deliversValueChanges = delegate?.subscribedEvents.contains(.valueChanges) ?? false
        }
    }

    /// Whether the delegate subscribed to value changes; the single branch a value write pays.
    @usableFromInline
    final var deliversValueChanges = false

    /// Initializes a new Nexus.
    /// - Parameter storage: The storage to keep entities and components in. Defaults to ``StorageKind/default``.
    public init(storage: StorageKind = .default) {
        backend = Backend(storage)
        familyMembersByTraits = [:]
        familyFiltersByTraits = [:]
        familyList = []
        entityIdGenerator = DefaultEntityIdGenerator()
        codingStrategy = DefaultCodingStrategy()
        componentRegistry = ComponentRegistry()
    }

    deinit {
        clear()
    }

    /// Clears all data from the Nexus.
    ///
    /// This removes all components, entities, and family memberships.
    public final func clear() {
        backend.removeAll()
        familyMembersByTraits.removeAll()
        familyFiltersByTraits.removeAll()
        familyList.removeAll()
    }
}

extension Nexus: @unchecked Sendable {}

// MARK: - CustomDebugStringConvertible

extension Nexus: CustomDebugStringConvertible {
    /// A textual representation of the Nexus, suitable for debugging.
    public var debugDescription: String {
        "<Nexus entities:\(numEntities) components:\(numComponents) families:\(numFamilies)>"
    }
}

// MARK: - default coding strategy

/// The default coding strategy used by `Nexus`.
///
/// This strategy uses the component type name as the string key.
public struct DefaultCodingStrategy: CodingStrategy {
    /// Creates a new default coding strategy.
    public init() {}

    /// Returns a coding key based on the component type name.
    /// - Parameter componentType: The component type.
    /// - Returns: A `DynamicCodingKey` initialized with the component type name.
    public func codingKey<C: Component>(for componentType: C.Type) -> DynamicCodingKey {
        DynamicCodingKey(stringValue: "\(C.self)").unsafelyUnwrapped
    }
}
