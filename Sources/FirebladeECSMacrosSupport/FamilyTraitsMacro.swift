//
//  FamilyTraitsMacro.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 25.10.26.
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Implements `FamilyTraitsProviding` and a typed `forEach` for a struct.
public struct FamilyTraitsMacro {}

extension FamilyTraitsMacro {
    /// The analyzed declaration of a `@FamilyTraits` struct.
    struct Declaration {
        /// The access modifier for generated members, including a trailing space, or empty for internal.
        let accessModifier: String
        /// The name of the struct.
        let typeName: String
        /// The spelled component types that are only read.
        let reading: [String]
        /// The spelled component types that are changed in place.
        let writing: [String]
        /// The spelled component types that must be absent.
        let excluding: [String]

        var required: [String] { reading + writing }
    }

    /// The three argument groups in declaration order.
    private static let argumentLabels = ["reading", "writing", "excluding"]

    /// Analyzes a declaration annotated with `@FamilyTraits`.
    /// - Returns: The analyzed declaration, or `nil` if it is not usable, and the diagnostics found.
    static func analyze(_ declaration: some DeclGroupSyntax, attribute: AttributeSyntax) -> (Declaration?, [Diagnostic]) {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return (nil, [Diagnostic(node: attribute, message: DiagnosticKind.requiresStruct)])
        }
        var diagnostics: [Diagnostic] = []
        var groups: [String: [(name: String, node: ExprSyntax)]] = [:]
        if case let .argumentList(arguments) = attribute.arguments {
            // Unlabeled arguments continue the group of the preceding labeled one (variadic parameters).
            var current = ""
            for argument in arguments {
                if let label = argument.label?.text {
                    current = label
                }
                guard argumentLabels.contains(current) else {
                    continue
                }
                guard let name = metatypeName(argument.expression) else {
                    diagnostics.append(Diagnostic(node: argument.expression, message: DiagnosticKind.expectsMetatype))
                    continue
                }
                groups[current, default: []].append((name, argument.expression))
            }
        }
        let reading = groups["reading"] ?? []
        let writing = groups["writing"] ?? []
        let excluding = groups["excluding"] ?? []

        if reading.isEmpty, writing.isEmpty, diagnostics.isEmpty {
            diagnostics.append(Diagnostic(node: attribute, message: DiagnosticKind.requiresComponents))
        }
        var seen = Set<String>()
        for entry in reading + writing + excluding {
            if !seen.insert(entry.name).inserted {
                let written = writing.contains { $0.name == entry.name }
                let kind: DiagnosticKind = if written, reading.contains(where: { $0.name == entry.name }) {
                    .readAndWrittenType
                } else if excluding.contains(where: { $0.name == entry.name }), reading.contains(where: { $0.name == entry.name }) || written {
                    .requiredAndExcludedType
                } else {
                    .duplicateType
                }
                diagnostics.append(Diagnostic(node: entry.node, message: kind))
            }
        }
        guard diagnostics.isEmpty else {
            return (nil, diagnostics)
        }
        let analyzed = Declaration(
            accessModifier: accessModifier(of: structDecl.modifiers),
            typeName: structDecl.name.text,
            reading: reading.map(\.name),
            writing: writing.map(\.name),
            excluding: excluding.map(\.name)
        )
        return (analyzed, diagnostics)
    }

    /// The spelled type of a `Type.self` expression, or `nil` for anything else.
    private static func metatypeName(_ expression: ExprSyntax) -> String? {
        guard let access = expression.as(MemberAccessExprSyntax.self),
              access.declName.baseName.text == "self",
              let base = access.base
        else {
            return nil
        }
        return base.trimmedDescription
    }

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
}

extension FamilyTraitsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let (analyzed, diagnostics) = analyze(declaration, attribute: node)
        diagnostics.forEach(context.diagnose)
        guard let family = analyzed else {
            return []
        }
        let access = family.accessModifier
        let name = family.typeName
        let boundType = "FirebladeECS.Family<\(family.required.joined(separator: ", "))>"
        let selfTypes = { (types: [String]) in types.map { "\($0).self" }.joined(separator: ", ") }
        let identifiers = { (types: [String]) in types.isEmpty ? "[]" : "[\(types.map { "\($0).identifier" }.joined(separator: ", "))]" }
        return [
            "\(raw: access)typealias Bound = \(raw: boundType)",
            """
            \(raw: access)static let traits = FirebladeECS.FamilyTraitSet(requiresAll: [\(raw: selfTypes(family.required))], excludesAll: [\(raw: selfTypes(family.excluding))])
            """,
            "\(raw: access)static let readComponents: Set<FirebladeECS.ComponentIdentifier> = \(raw: identifiers(family.reading))",
            "\(raw: access)static let writeComponents: Set<FirebladeECS.ComponentIdentifier> = \(raw: identifiers(family.writing))",
            "\(raw: access)static let familyIndex = FirebladeECS.Nexus.familyIndex(of: \(raw: name).self)",
            "\(raw: access)let family: \(raw: boundType)",
            """
            \(raw: access)static func makeFamily(in nexus: FirebladeECS.Nexus) -> \(raw: boundType) {
                \(raw: boundType)(nexus: nexus, requiresAll: \(raw: selfTypes(family.required)), excludesAll: [\(raw: selfTypes(family.excluding))])
            }
            """,
            """
            \(raw: access)init(in nexus: FirebladeECS.Nexus) {
                family = nexus.family(for: \(raw: name).self)
            }
            """,
            forEachMember(family)
        ]
    }

    /// Generates the typed `forEach`, calling the fixed arity overload or the pack fallback.
    private static func forEachMember(_ family: Declaration) -> DeclSyntax {
        let reads = family.reading
        let writes = family.writing
        let closureParameters = reads + writes.map { "inout \($0)" }
        let closureType = "(\(closureParameters.joined(separator: ", "))) throws -> Void"
        let doc = """
        /// Calls `body` with the read components and the in-place changed components of every member.
        ///
        /// Forwards to `Family.forEach(reading:writing:)`.
        """
        var call: String
        if reads.count <= 4, writes.count <= 4 {
            var arguments: [String] = []
            if let first = reads.first {
                arguments.append("reading: \(first).self")
                arguments.append(contentsOf: reads.dropFirst().map { "\($0).self" })
            }
            if let first = writes.first {
                arguments.append("writing: \(first).self")
                arguments.append(contentsOf: writes.dropFirst().map { "\($0).self" })
            }
            arguments.append("body")
            call = "try family.forEach(\(arguments.joined(separator: ", ")))"
        } else {
            // The pack fallback receives the written components as one inout tuple, before the read ones.
            let readNames = reads.indices.map { "r\($0)" }
            let parameters = ["written: inout (\(writes.joined(separator: ", ")))"] + zip(readNames, reads).map { "\($0): \($1)" }
            let forwarded = readNames + (writes.count == 1 ? ["&written"] : writes.indices.map { "&written.\($0)" })
            var typeArguments: [String] = []
            if !reads.isEmpty {
                typeArguments.append("reading: \(reads.map { "\($0).self" }.joined(separator: ", "))")
            }
            if !writes.isEmpty {
                typeArguments.append("writing: \(writes.map { "\($0).self" }.joined(separator: ", "))")
            }
            let types = typeArguments.joined(separator: ", ")
            call = """
            try family.forEach(\(types)) { (\(parameters.joined(separator: ", "))) in
                    try body(\(forwarded.joined(separator: ", ")))
                }
            """
        }
        return """
        \(raw: doc)
        \(raw: family.accessModifier)func forEach(_ body: \(raw: closureType)) rethrows {
            \(raw: call)
        }
        """
    }
}

extension FamilyTraitsMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard analyze(declaration, attribute: node).0 != nil,
              protocols.contains(where: { $0.trimmedDescription.split(separator: ".").last == "FamilyTraitsProviding" })
        else {
            return []
        }
        return try [ExtensionDeclSyntax("extension \(type.trimmed): FirebladeECS.FamilyTraitsProviding {}")]
    }
}
