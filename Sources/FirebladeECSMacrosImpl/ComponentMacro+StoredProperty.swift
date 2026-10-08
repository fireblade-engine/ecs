//
//  ComponentMacro+StoredProperty.swift
//  FirebladeECSMacrosImpl
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftSyntax

extension ComponentMacro {
    /// A stored instance property of a `@Component` class.
    struct StoredProperty {
        /// The property name.
        let name: String
        /// The declared type, if annotated.
        let type: TypeSyntax?
        /// Whether the property is declared with `let`.
        let isLet: Bool
        /// Whether the property has an initial value.
        let hasInitializer: Bool
        /// Whether the property is marked `@ComponentIgnored`.
        let isIgnored: Bool
        /// The syntax node to attach diagnostics to.
        let node: Syntax

        /// The wrapped type if the declared type is an optional, otherwise `nil`.
        var optionalWrappedType: TypeSyntax? {
            guard let type else {
                return nil
            }
            if let optional = type.as(OptionalTypeSyntax.self) {
                return optional.wrappedType
            }
            if let implicitlyUnwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
                return implicitlyUnwrapped.wrappedType
            }
            guard let identifier = type.as(IdentifierTypeSyntax.self), identifier.name.text == "Optional" else {
                return nil
            }
            return identifier.genericArgumentClause?.arguments.first?.argument.as(TypeSyntax.self)
        }

        /// Whether the property is a constant whose value is fixed by its declaration.
        var isConstant: Bool {
            isLet && hasInitializer
        }

        /// Whether the property is initialized without an explicit assignment in an initializer.
        var hasDefaultValue: Bool {
            hasInitializer || (!isLet && optionalWrappedType != nil)
        }

        /// Whether the property is assigned when cloning.
        var isCloned: Bool {
            !isConstant
        }

        /// Whether the property is encoded and decoded.
        var isSerialized: Bool {
            !isConstant && !isIgnored
        }

        /// Whether the property is listed for inspection.
        var isInspected: Bool {
            !isIgnored
        }
    }
}
