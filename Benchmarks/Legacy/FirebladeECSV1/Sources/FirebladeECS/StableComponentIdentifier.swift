//
//  StableComponentIdentifier.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Identifies a component type by a hash of its stable type name.
///
/// Unlike ``ComponentIdentifier``, which is derived from the runtime meta type and changes
/// between process launches, a stable component identifier is deterministic across processes,
/// builds and platforms. Use it for persistent or networked representations of component types.
public struct StableComponentIdentifier {
    /// The 64-bit FNV-1a hash of the component type name.
    public let rawValue: UInt64

    /// Creates a stable identifier from a raw hash value.
    /// - Parameter rawValue: The raw hash value.
    /// - Complexity: O(1)
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    /// Creates a stable identifier by hashing a component type name.
    /// - Parameter typeName: The stable component type name.
    /// - Complexity: O(N) where N is the number of UTF-8 code units of the type name.
    public init(typeName: String) {
        // 64-bit FNV-1a: http://www.isthe.com/chongo/tech/comp/fnv/
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in typeName.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01B3
        }
        rawValue = hash
    }
}

extension StableComponentIdentifier: Equatable {}
extension StableComponentIdentifier: Hashable {}
extension StableComponentIdentifier: Sendable {}
extension StableComponentIdentifier: Codable {
    /// Encodes the raw hash value into a single value container.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Decodes a stable identifier from a single raw hash value.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(UInt64.self))
    }
}
