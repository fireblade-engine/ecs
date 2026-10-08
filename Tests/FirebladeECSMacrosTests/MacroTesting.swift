//
//  MacroTesting.swift
//  FirebladeECSMacrosTests
//
//  Created by Christian Treffs on 08.10.26.
//

#if canImport(FirebladeECSMacrosSupport)
import FirebladeECSMacrosSupport
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// The macros under test with the conformances the compiler would request.
let componentMacroSpecs: [String: MacroSpec] = [
    "Component": MacroSpec(
        type: ComponentMacro.self,
        conformances: ["RegistrableComponent", "CloneableComponent", "SerializableComponent", "InspectableComponent", "DefaultInitializable"]
    ),
    "ComponentIgnored": MacroSpec(type: ComponentIgnoredMacro.self)
]

/// Asserts a macro expansion and reports failures as Swift Testing issues.
func assertComponentExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: componentMacroSpecs,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: failure.location.fileID,
                    filePath: failure.location.filePath,
                    line: failure.location.line,
                    column: failure.location.column
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}
#endif
