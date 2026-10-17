//
//  ImpliedConformanceComponent.swift
//  FirebladeECSMacrosTests
//

import FirebladeECSMacros

/// Declared in its own file: `ImpliedConformanceTests.swift` looks up `Kind` before it uses the type as a
/// component, which builds the conformance table before the macro is expanded.
@Component(excluding: [.serializable, .cloneable, .inspectable])
final class MacroImpliedConformance: @unchecked Sendable {
    enum Kind {
        case first, second
    }

    var kind: Kind = .first
}
