//
//  ComponentMacro+StoredEntity.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 25.10.26.
//

import SwiftDiagnostics
import SwiftSyntax

extension ComponentMacro {
    /// Finds stored `Entity` references in a property type.
    ///
    /// Recognizes `Entity`, `Entity?`, `Entity!`, `Optional<Entity>`, `[Entity]`, `Array<Entity>`, `Set<Entity>`,
    /// `[Key: Entity]` and `Dictionary<Key, Entity>`, also qualified with `FirebladeECS.`.
    /// An `Entity` behind a typealias or a nested type is not visible to a macro and stays a convention.
    enum StoredEntity {
        /// The name tokens spelling `Entity` in a type.
        static func tokens(in type: TypeSyntax) -> [TokenSyntax] {
            if let identifier = type.as(IdentifierTypeSyntax.self) {
                return tokens(in: identifier)
            }
            if let member = type.as(MemberTypeSyntax.self) {
                guard member.baseType.trimmedDescription == "FirebladeECS", member.name.text == "Entity" else {
                    return []
                }
                return [member.name]
            }
            if let optional = type.as(OptionalTypeSyntax.self) {
                return tokens(in: optional.wrappedType)
            }
            if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
                return tokens(in: optional.wrappedType)
            }
            if let array = type.as(ArrayTypeSyntax.self) {
                return tokens(in: array.element)
            }
            if let dictionary = type.as(DictionaryTypeSyntax.self) {
                return tokens(in: dictionary.value)
            }
            return []
        }

        private static func tokens(in identifier: IdentifierTypeSyntax) -> [TokenSyntax] {
            guard let arguments = identifier.genericArgumentClause?.arguments else {
                return identifier.name.text == "Entity" ? [identifier.name] : []
            }
            switch identifier.name.text {
            case "Optional", "Array", "Set":
                return arguments.compactMap { $0.argument.as(TypeSyntax.self) }.flatMap(tokens(in:))

            case "Dictionary":
                return arguments.last?.argument.as(TypeSyntax.self).map(tokens(in:)) ?? []

            default:
                return []
            }
        }

        /// Creates the diagnostic with a fix-it replacing the `Entity` spelling by `EntityIdentifier`.
        static func diagnostic(for token: TokenSyntax) -> Diagnostic {
            let replacement = TokenSyntax.identifier("EntityIdentifier", leadingTrivia: token.leadingTrivia, trailingTrivia: token.trailingTrivia)
            return Diagnostic(
                node: token,
                message: ComponentMacro.DiagnosticKind.storedEntity,
                fixIt: FixIt(
                    message: ComponentMacro.FixItKind.useEntityIdentifier,
                    changes: [.replace(oldNode: Syntax(token), newNode: Syntax(replacement))]
                )
            )
        }
    }

    /// Fix-its offered by `@Component`.
    enum FixItKind: String, FixItMessage {
        case useEntityIdentifier

        var message: String {
            "replace 'Entity' with 'EntityIdentifier'"
        }

        var fixItID: MessageID {
            MessageID(domain: "FirebladeECSMacros", id: rawValue)
        }
    }
}
