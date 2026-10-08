//
//  ComponentMacro+Declaration.swift
//  FirebladeECSMacrosImpl
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftDiagnostics
import SwiftSyntax

extension ComponentMacro {
    /// The analyzed declaration of a `@Component` class.
    struct Declaration {
        /// The access modifier for generated members, including a trailing space, or empty for internal.
        let accessModifier: String
        /// The name of the class.
        let typeName: String
        /// The stored instance properties in declaration order.
        let properties: [ComponentMacro.StoredProperty]
        /// The features to implement.
        let features: Features
        /// The members the class declares itself.
        let declaredMembers: DeclaredMembers
    }
}

extension ComponentMacro.Declaration {
    /// The implementable features of a component.
    struct Features {
        var isCloneable = true
        var isSerializable = true
        var isInspectable = true
        var isDefaultInitializable = true
    }

    /// Members relevant to generation that the class declares itself.
    struct DeclaredMembers {
        var defaultInit = false
        var cloning = false
        var codable = false
        var componentProperties = false
    }
}

extension ComponentMacro.Declaration {
    /// Analyzes a declaration annotated with `@Component`.
    ///
    /// Features whose requirements are not met are disabled.
    /// - Returns: The analyzed declaration, or `nil` if the declaration is not a final class, and the diagnostics found.
    static func analyze(_ declaration: some DeclGroupSyntax, attribute: AttributeSyntax) -> (Self?, [Diagnostic]) {
        guard let classDecl = declaration.as(ClassDeclSyntax.self),
              classDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.final) })
        else {
            return (nil, [Diagnostic(node: attribute, message: ComponentMacro.DiagnosticKind.requiresFinalClass)])
        }

        var diagnostics: [Diagnostic] = []
        var features = parseFeatures(attribute, diagnostics: &diagnostics)
        let properties = collectStoredProperties(classDecl.memberBlock, diagnostics: &diagnostics)
        let declaredMembers = collectDeclaredMembers(classDecl.memberBlock)

        for property in properties where property.isIgnored && !property.hasDefaultValue {
            diagnostics.append(Diagnostic(node: property.node, message: ComponentMacro.DiagnosticKind.ignoredPropertyRequiresDefaultValue))
            features.isSerializable = false
        }
        if features.isSerializable, !declaredMembers.codable {
            for property in properties where property.isSerialized && property.type == nil {
                diagnostics.append(Diagnostic(node: property.node, message: ComponentMacro.DiagnosticKind.serializedPropertyRequiresTypeAnnotation))
                features.isSerializable = false
            }
        }
        if !declaredMembers.defaultInit, !properties.allSatisfy(\.hasDefaultValue) {
            features.isDefaultInitializable = false
        }

        let declaration = Self(
            accessModifier: accessModifier(of: classDecl.modifiers),
            typeName: classDecl.name.text,
            properties: properties,
            features: features,
            declaredMembers: declaredMembers
        )
        return (declaration, diagnostics)
    }

    /// Returns the access modifier generated members should use.
    private static func accessModifier(of modifiers: DeclModifierListSyntax) -> String {
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open):
                return "public "

            case .keyword(.package):
                return "package "

            default:
                continue
            }
        }
        return ""
    }

    /// Parses the `excluding:` argument.
    private static func parseFeatures(_ attribute: AttributeSyntax, diagnostics: inout [Diagnostic]) -> Features {
        var features = Features()
        guard case let .argumentList(arguments) = attribute.arguments,
              let excluding = arguments.first(where: { $0.label?.text == "excluding" })
        else {
            return features
        }

        let expressions: [ExprSyntax] = if let array = excluding.expression.as(ArrayExprSyntax.self) {
            array.elements.map(\.expression)
        } else {
            [excluding.expression]
        }

        for expression in expressions {
            guard let memberAccess = expression.as(MemberAccessExprSyntax.self) else {
                diagnostics.append(Diagnostic(node: expression, message: ComponentMacro.DiagnosticKind.unsupportedExcludingArgument))
                continue
            }
            switch memberAccess.declName.baseName.text {
            case "cloneable":
                features.isCloneable = false

            case "serializable":
                features.isSerializable = false

            case "inspectable":
                features.isInspectable = false

            case "defaultInit":
                features.isDefaultInitializable = false

            default:
                diagnostics.append(Diagnostic(node: expression, message: ComponentMacro.DiagnosticKind.unsupportedExcludingArgument))
            }
        }
        return features
    }

    /// Collects the stored instance properties of a member block.
    private static func collectStoredProperties(_ memberBlock: MemberBlockSyntax, diagnostics: inout [Diagnostic]) -> [ComponentMacro.StoredProperty] {
        var properties: [ComponentMacro.StoredProperty] = []
        for member in memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  !variable.modifiers.contains(where: { [.keyword(.static), .keyword(.class)].contains($0.name.tokenKind) })
            else {
                continue
            }
            let isLet = variable.bindingSpecifier.tokenKind == .keyword(.let)
            let isIgnored = variable.attributes.contains { element in
                guard case let .attribute(attribute) = element else {
                    return false
                }
                return attribute.attributeName.trimmedDescription.hasSuffix("ComponentIgnored")
            }
            let isLazy = variable.modifiers.contains { $0.name.tokenKind == .keyword(.lazy) }

            // A type annotation applies to all preceding bindings without one, e.g. `var x, y: Int`.
            var trailingType: TypeSyntax?
            var collected: [ComponentMacro.StoredProperty] = []
            for binding in variable.bindings.reversed() {
                if let annotated = binding.typeAnnotation?.type {
                    trailingType = annotated
                }
                guard isStored(binding) else {
                    continue
                }
                guard !isLazy else {
                    diagnostics.append(Diagnostic(node: binding, message: ComponentMacro.DiagnosticKind.unsupportedLazyProperty))
                    continue
                }
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    diagnostics.append(Diagnostic(node: binding, message: ComponentMacro.DiagnosticKind.unsupportedPattern))
                    continue
                }
                collected.append(ComponentMacro.StoredProperty(
                    name: identifier.identifier.trimmedDescription,
                    type: trailingType?.trimmed,
                    isLet: isLet,
                    hasInitializer: binding.initializer != nil,
                    isIgnored: isIgnored,
                    node: Syntax(binding)
                ))
            }
            properties.append(contentsOf: collected.reversed())
        }
        return properties
    }

    /// Returns whether a binding is stored, i.e. has no accessors other than observers.
    private static func isStored(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else {
            return true
        }
        guard case let .accessors(accessors) = accessorBlock.accessors else {
            return false
        }
        return accessors.allSatisfy { [.keyword(.willSet), .keyword(.didSet)].contains($0.accessorSpecifier.tokenKind) }
    }

    /// Collects the members relevant to generation that a member block declares.
    private static func collectDeclaredMembers(_ memberBlock: MemberBlockSyntax) -> DeclaredMembers {
        var declared = DeclaredMembers()
        for member in memberBlock.members {
            let decl = member.decl
            if let initializer = decl.as(InitializerDeclSyntax.self) {
                let labels = initializer.signature.parameterClause.parameters.map(\.firstName.text)
                if labels.isEmpty {
                    declared.defaultInit = true
                } else if labels == ["from"] {
                    declared.codable = true
                }
            } else if let function = decl.as(FunctionDeclSyntax.self) {
                let labels = function.signature.parameterClause.parameters.map(\.firstName.text)
                if function.name.text == "encode", labels == ["to"] {
                    declared.codable = true
                } else if function.name.text == "clone", labels == ["context"] {
                    declared.cloning = true
                }
            } else if let enumDecl = decl.as(EnumDeclSyntax.self), enumDecl.name.text == "CodingKeys" {
                declared.codable = true
            } else if let variable = decl.as(VariableDeclSyntax.self), declares(variable, named: "componentProperties") {
                declared.componentProperties = true
            }
        }
        return declared
    }

    /// Returns whether a variable declaration binds the given name.
    private static func declares(_ variable: VariableDeclSyntax, named name: String) -> Bool {
        variable.bindings.contains { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name }
    }
}
