//
//  ComponentMacro.swift
//  FirebladeECSMacrosSupport
//
//  Created by Christian Treffs on 08.10.26.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Implements component protocols for a final class from its stored properties.
public struct ComponentMacro {}

extension ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let (analyzed, diagnostics) = Declaration.analyze(declaration, attribute: node)
        diagnostics.forEach(context.diagnose)
        guard let component = analyzed else {
            return []
        }

        var members: [DeclSyntax] = []
        if component.features.isCloneable, !component.declaredMembers.cloning {
            members.append(contentsOf: cloningMembers(component))
        }
        if component.features.isSerializable, !component.declaredMembers.codable {
            members.append(contentsOf: codableMembers(component))
        }
        if component.features.isInspectable, !component.declaredMembers.componentProperties {
            members.append(inspectionMember(component))
        }
        if component.features.isDefaultInitializable, !component.declaredMembers.defaultInit {
            members.append("\(raw: component.accessModifier)init() {}")
        }
        return members
    }

    /// Generates `init(cloning:context:)` and `clone(context:)`.
    private static func cloningMembers(_ component: Declaration) -> [DeclSyntax] {
        let access = component.accessModifier
        let assignments = component.properties
            .filter(\.isCloned)
            .map { "self.\($0.name) = context.clone(other.\($0.name))" }
        return [
            """
            \(raw: access)init(cloning other: \(raw: component.typeName), context: FirebladeECS.ComponentCloneContext) {\(raw: block(assignments))}
            """,
            """
            \(raw: access)func clone(context: FirebladeECS.ComponentCloneContext) -> \(raw: component.typeName) {
                \(raw: component.typeName)(cloning: self, context: context)
            }
            """
        ]
    }

    /// Generates `CodingKeys`, `init(from:)` and `encode(to:)`.
    private static func codableMembers(_ component: Declaration) -> [DeclSyntax] {
        let access = component.accessModifier
        let serialized = component.properties.filter(\.isSerialized)
        guard !serialized.isEmpty else {
            return [
                "\(raw: access)init(from _: any Swift.Decoder) throws {}",
                "\(raw: access)func encode(to _: any Swift.Encoder) throws {}"
            ]
        }

        let cases = serialized.map { "case \($0.name)" }
        var decodings: [String] = []
        var encodings: [String] = []
        for property in serialized {
            if let wrapped = property.optionalWrappedType {
                decodings.append("self.\(property.name) = try container.decodeIfPresent(\(wrapped.trimmedDescription).self, forKey: .\(property.name))")
                encodings.append("try container.encodeIfPresent(self.\(property.name), forKey: .\(property.name))")
            } else if let type = property.type {
                decodings.append("self.\(property.name) = try container.decode(\(type.trimmedDescription).self, forKey: .\(property.name))")
                encodings.append("try container.encode(self.\(property.name), forKey: .\(property.name))")
            }
        }
        return [
            """
            private enum CodingKeys: String, Swift.CodingKey {
            \(raw: indented(cases))
            }
            """,
            """
            \(raw: access)init(from decoder: any Swift.Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
            \(raw: indented(decodings))
            }
            """,
            """
            \(raw: access)func encode(to encoder: any Swift.Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
            \(raw: indented(encodings))
            }
            """
        ]
    }

    /// Generates `componentProperties`.
    private static func inspectionMember(_ component: Declaration) -> DeclSyntax {
        let typeName = component.typeName
        let entries = component.properties
            .filter(\.isInspected)
            .map { "FirebladeECS.ComponentProperty(name: \"\($0.name)\", keyPath: \\\(typeName).\($0.name))" }
        let list = entries.isEmpty ? "[]" : "[\n\(indented(entries, separator: ",\n", depth: 2))\n    ]"
        return """
        \(raw: component.accessModifier)static var componentProperties: [FirebladeECS.ComponentProperty<\(raw: typeName)>] {
            \(raw: list)
        }
        """
    }

    /// Formats lines as the indented body of a code block, including surrounding line breaks.
    private static func block(_ lines: [String]) -> String {
        lines.isEmpty ? "\n" : "\n\(indented(lines))\n"
    }

    /// Indents lines by four spaces per depth level.
    private static func indented(_ lines: [String], separator: String = "\n", depth: Int = 1) -> String {
        let indentation = String(repeating: "    ", count: depth)
        return lines.map { indentation + $0 }.joined(separator: separator)
    }
}

extension ComponentMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let (analyzed, _) = Declaration.analyze(declaration, attribute: node)
        guard let component = analyzed else {
            return []
        }

        let missing = Set(protocols.compactMap { $0.trimmedDescription.split(separator: ".").last.map(String.init) })
        let features = component.features
        let candidates: [(name: String, isEnabled: Bool)] = [
            ("RegistrableComponent", true),
            ("CloneableComponent", features.isCloneable),
            ("SerializableComponent", features.isSerializable),
            ("InspectableComponent", features.isInspectable),
            ("DefaultInitializable", features.isDefaultInitializable)
        ]
        let conformances = candidates
            .filter { $0.isEnabled && missing.contains($0.name) }
            .map { "FirebladeECS.\($0.name)" }
        guard !conformances.isEmpty else {
            return []
        }
        return try [ExtensionDeclSyntax("extension \(type.trimmed): \(raw: conformances.joined(separator: ", ")) {}")]
    }
}
