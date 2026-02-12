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
#endif
