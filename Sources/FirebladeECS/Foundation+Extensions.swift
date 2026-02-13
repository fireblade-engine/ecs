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

#if canImport(Darwin) || swift(>=6.2)
public typealias UserInfoValue = any Sendable
#else
public typealias UserInfoValue = Any
#endif

/// A type that can encode values into a native format.
public protocol TopLevelEncoder {
    /// The type this encoder produces.
    associatedtype Output

    /// Encodes an instance of the indicated type.
    ///
    /// - Parameter value: The instance to encode.
    /// - Returns: The encoded data.
    /// - Throws: An error if encoding fails.
    func encode<T: Encodable>(_ value: T) throws -> Self.Output

    /// Contextual user-provided information for use during decoding.
    var userInfo: [CodingUserInfoKey: UserInfoValue] { get set }
}


/// A type that can decode values from a native format.
public protocol TopLevelDecoder {
    /// The type this decoder accepts.
    associatedtype Input

    /// Decodes an instance of the indicated type.
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - from: The data to decode from.
    /// - Returns: The decoded value.
    /// - Throws: An error if decoding fails.
    func decode<T: Decodable>(_ type: T.Type, from: Self.Input) throws -> T

    /// Contextual user-provided information for use during decoding.
    var userInfo: [CodingUserInfoKey: UserInfoValue] { get set }
}
#endif
