//
//  ComponentIgnoredMacro.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marks a stored property to be ignored by `@Component`. Expands to nothing.
public struct ComponentIgnoredMacro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf _: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
