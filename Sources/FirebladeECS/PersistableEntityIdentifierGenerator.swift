//
//  PersistableEntityIdentifierGenerator.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 09.10.26.
//

/// An entity identifier generator whose state can be saved in a ``NexusSnapshot``.
///
/// Restoring a snapshot with ``Nexus/restoreSnapshot(from:using:)`` installs the saved generator state,
/// so that the restored nexus provides the same entity identifiers the original nexus would have provided next.
/// Generators that do not conform still restore the entity identifiers of the snapshot, but not their recycling order.
public protocol PersistableEntityIdentifierGenerator: EntityIdentifierGenerator, Codable {}

extension LinearIncrementingEntityIdGenerator: PersistableEntityIdentifierGenerator {
    /// The coding keys of a linear incrementing entity id generator.
    enum CodingKeys: String, CodingKey {
        /// The identifier provided once no recycled identifiers are left.
        case nextFreshId
        /// The recycled identifiers, provided next in last out order.
        case recycled
    }

    /// Encodes the state of the generator.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    /// - Complexity: O(N) where N is the number of recycled identifiers.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storage.stack[0], forKey: .nextFreshId)
        try container.encode(Array(storage.stack.dropFirst()), forKey: .recycled)
    }

    /// Decodes the state of a generator.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails or a recycled identifier is not lower than the next fresh identifier.
    /// - Complexity: O(N) where N is the number of recycled identifiers.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nextFreshId = try container.decode(EntityIdentifier.Identifier.self, forKey: .nextFreshId)
        let recycled = try container.decode([EntityIdentifier.Identifier].self, forKey: .recycled)
        guard recycled.allSatisfy({ $0 < nextFreshId }) else {
            throw DecodingError.dataCorruptedError(forKey: .recycled,
                                                   in: container,
                                                   debugDescription: "Recycled entity identifiers must be lower than nextFreshId \(nextFreshId).")
        }
        self.init()
        storage.stack = [nextFreshId] + recycled
    }
}
