//
//  ComponentIgnoredMacro.swift
//  FirebladeECSMacrosImpl
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECSMacrosSupport
import SwiftSyntax
import SwiftSyntaxMacros

/// The `@ComponentIgnored` entry point of the compiler plugin.
///
/// The compiler resolves macro types by their module-qualified name, so this type lives in the
/// plugin module and forwards to the implementation in `FirebladeECSMacrosSupport`.
public struct ComponentIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try FirebladeECSMacrosSupport.ComponentIgnoredMacro.expansion(
            of: node,
            providingPeersOf: declaration,
            in: context
        )
    }
}
