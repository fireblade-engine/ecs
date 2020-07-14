//
//  Version.swift
//
//
//  Created by Christian Treffs on 14.07.20.
//

public struct Version {
    public let major: UInt
    public let minor: UInt
    public let patch: UInt
}

extension Version: Equatable { }
extension Version: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(major).\(minor).\(patch)")
    }
}
extension Version: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let versionString = try container.decode(String.self)
        let components = versionString.components(separatedBy: ".")
        guard components.count == 3 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed version.")
        }

        guard let major = UInt(components[0]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Major invalid.")
        }

        guard let minor = UInt(components[1]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Minor invalid.")
        }

        guard let patch = UInt(components[2]) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Patch invalid.")
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }
}
