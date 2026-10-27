//
//  ImpliedConformanceComponent.swift
//  FirebladeECSMacrosTests
//

import FirebladeECS
import FirebladeECSMacros

/// Declared in its own file: `ImpliedConformanceTests.swift` looks up `Kind` before it uses the type as a
/// component, which builds the conformance table before the macro is expanded.
@Component(excluding: [.serializable, .cloneable, .inspectable])
struct MacroImpliedConformance {
    enum Kind {
        case first, second
    }

    var kind: Kind = .first
}
