//
//  Foundation+Extensions.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 22.07.20.
//

#if canImport(Foundation)
import Foundation

/// Conformance of `JSONEncoder` to `TopLevelEncoder` to support JSON encoding in ECS serialization.
extension JSONEncoder: TopLevelEncoder {}
/// Conformance of `JSONDecoder` to `TopLevelDecoder` to support JSON decoding in ECS serialization.
extension JSONDecoder: TopLevelDecoder {}

/// A type that can encode values into a native format.
public protocol TopLevelEncoder {
    /// The type this encoder produces.
    associatedtype Output

    /// Encodes an instance of the indicated type.
    ///
    /// - Parameter value: The instance to encode.
    /// - Returns: The encoded data.
    /// - Throws: An error if encoding fails.
    func encode<T>(_ value: T) throws -> Self.Output where T : Encodable
}

/// A type that can decode values from a native format.
public protocol TopLevelDecoder {
    /// The type this decoder accepts.
    associatedtype Input

    /// Decodes an instance of the indicated type.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: An error if decoding fails.
    func decode<T>(_ type: T.Type, from: Self.Input) throws -> T where T : Decodable
}
#endif
