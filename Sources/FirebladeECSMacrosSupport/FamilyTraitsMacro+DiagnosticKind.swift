//
//  FamilyTraitsMacro+DiagnosticKind.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 25.10.26.
//

import SwiftDiagnostics

extension FamilyTraitsMacro {
    /// Diagnostics emitted by `@FamilyTraits`.
    enum DiagnosticKind: String, DiagnosticMessage {
        case requiresStruct
        case requiresComponents
        case expectsMetatype
        case readAndWrittenType
        case duplicateType
        case requiredAndExcludedType

        var message: String {
            switch self {
            case .requiresStruct:
                "@FamilyTraits can only be applied to a struct"

            case .requiresComponents:
                "@FamilyTraits requires at least one type in 'reading:' or 'writing:'"

            case .expectsMetatype:
                "@FamilyTraits expects component metatypes such as 'Position.self'"

            case .readAndWrittenType:
                "a component type can not be both read and written; list it in 'writing:' only"

            case .duplicateType:
                "component type is listed more than once"

            case .requiredAndExcludedType:
                "a component type can not be both required and excluded"
            }
        }

        var diagnosticID: MessageID {
            MessageID(domain: "FirebladeECSMacros", id: rawValue)
        }

        var severity: DiagnosticSeverity {
            .error
        }
    }
}
