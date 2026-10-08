//
//  ComponentMacro.swift
//  FirebladeECSMacrosImpl
//
//  Created by Christian Treffs on 08.10.26.
//

import FirebladeECSMacrosSupport
import SwiftSyntax
import SwiftSyntaxMacros

/// The `@Component` entry point of the compiler plugin.
///
/// The compiler resolves macro types by their module-qualified name, so this type lives in the
/// plugin module and forwards to the implementation in `FirebladeECSMacrosSupport`.
public struct ComponentMacro {}

extension ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try FirebladeECSMacrosSupport.ComponentMacro.expansion(
            of: node,
            providingMembersOf: declaration,
            conformingTo: protocols,
            in: context
        )
    }
}

extension ComponentMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try FirebladeECSMacrosSupport.ComponentMacro.expansion(
            of: node,
            attachedTo: declaration,
            providingExtensionsOf: type,
            conformingTo: protocols,
            in: context
        )
    }
}
