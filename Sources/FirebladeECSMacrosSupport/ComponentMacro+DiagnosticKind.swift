//
//  ComponentMacro+DiagnosticKind.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftDiagnostics

extension ComponentMacro {
    /// Diagnostics emitted by `@Component`.
    enum DiagnosticKind: String, DiagnosticMessage {
        case requiresFinalClass
        case unsupportedLazyProperty
        case unsupportedPattern
        case unsupportedExcludingArgument
        case serializedPropertyRequiresTypeAnnotation
        case ignoredPropertyRequiresDefaultValue

        var message: String {
            switch self {
            case .requiresFinalClass:
                "@Component can only be applied to a final class"

            case .unsupportedLazyProperty:
                "@Component does not support lazy properties"

            case .unsupportedPattern:
                "@Component only supports stored properties bound to a single identifier"

            case .unsupportedExcludingArgument:
                "'excluding:' expects a ComponentMacroFeatures literal such as '.serializable' or '[.serializable, .inspectable]'"

            case .serializedPropertyRequiresTypeAnnotation:
                "serialized property requires an explicit type annotation; add one, mark the property @ComponentIgnored or use @Component(excluding: .serializable)"

            case .ignoredPropertyRequiresDefaultValue:
                "@ComponentIgnored property requires a default value"
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
