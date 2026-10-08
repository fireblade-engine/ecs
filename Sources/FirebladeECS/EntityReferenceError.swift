//
//  EntityReferenceError.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 08.10.26.
//

/// Errors raised while resolving encoded entity references.
public enum EntityReferenceError: Error, Equatable, Sendable {
    /// No ``EntityReferenceResolver`` was provided in the decoder's user info.
    case missingResolver
    /// The encoded entity identifier is not mapped by the resolver.
    case unresolved(EntityIdentifier)
}
