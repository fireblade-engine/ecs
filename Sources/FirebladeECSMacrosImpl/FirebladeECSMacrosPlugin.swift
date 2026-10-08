//
//  FirebladeECSMacrosPlugin.swift
//  FirebladeECSMacrosImpl
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler plugin providing the FirebladeECS macros.
@main
public struct FirebladeECSMacrosPlugin: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
        ComponentIgnoredMacro.self
    ]

    public init() {}
}
