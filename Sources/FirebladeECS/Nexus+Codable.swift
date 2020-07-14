//
//  Nexus+Codable.swift
//
//
//  Created by Christian Treffs on 14.07.20.
//

extension Nexus: Encodable {
    public func encode(to encoder: Encoder) throws {
        let serializedNexus = try self.serialize()
        var container = encoder.singleValueContainer()
        try container.encode(serializedNexus)
    }
}

extension Nexus: Decodable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let sNexus = try container.decode(SNexus.self)
        try self.init(from: sNexus)
    }
}
