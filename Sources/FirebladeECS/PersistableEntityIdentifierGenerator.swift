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
///
/// The persisted state must include the generations the generator hands out, so that a restored generator
/// never provides an identifier twice.
public protocol PersistableEntityIdentifierGenerator: EntityIdentifierGenerator, Codable {}

extension LinearIncrementingEntityIdGenerator: PersistableEntityIdentifierGenerator {
    /// The coding keys of a linear incrementing entity id generator.
    enum CodingKeys: String, CodingKey {
        /// The slot index provided once no recycled identifiers are left. It is provided with generation 1.
        case nextFreshId
        /// The recycled identifiers as raw values with their increased generations, provided next in last out order.
        case recycledIds
        /// The recycled slot indices of generator state written by format version 1 and 2, which did not persist generations.
        case recycled
    }

    /// Encodes the state of the generator.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    /// - Complexity: O(N) where N is the number of recycled identifiers.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storage.stack[0].index, forKey: .nextFreshId)
        try container.encode(storage.stack.dropFirst().map(\.rawValue), forKey: .recycledIds)
    }

    /// Decodes the state of a generator.
    ///
    /// State without `recycledIds` was written by an earlier version: its recycled slot indices decode with generation 1.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails or a recycled identifier is not lower than the next fresh identifier.
    /// - Complexity: O(N) where N is the number of recycled identifiers.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nextFreshId = try container.decode(EntityIdentifier.Index.self, forKey: .nextFreshId)
        let recycled: [EntityIdentifier]
        let recycledKey: CodingKeys
        if container.contains(.recycledIds) {
            recycledKey = .recycledIds
            recycled = try container.decode([UInt64].self, forKey: .recycledIds).map { EntityIdentifier(rawValue: $0) }
        } else {
            recycledKey = .recycled
            recycled = try container.decode([EntityIdentifier.Index].self, forKey: .recycled).map { EntityIdentifier(index: $0, generation: 1) }
        }
        guard recycled.allSatisfy({ $0.isValid && $0.index < nextFreshId }) else {
            throw DecodingError.dataCorruptedError(forKey: recycledKey,
                                                   in: container,
                                                   debugDescription: "Recycled entity identifiers must be valid and have an index lower than nextFreshId \(nextFreshId).")
        }
        self.init()
        storage.stack = [Storage.firstFresh(nextFreshId)] + recycled
    }
}
