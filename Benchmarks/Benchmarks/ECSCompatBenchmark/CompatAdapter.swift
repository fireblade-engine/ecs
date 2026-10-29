// Per-revision adapter of the shared compatibility suite. Everything that differs between FirebladeECS revisions
// lives here; the workloads in CompatWorkloads.swift compile unchanged against every revision.
//
// ECS_CLASS_COMPONENTS is set by Scripts/benchmark-snapshot.sh when the snapshot declares
// `protocol Component: AnyObject` (FirebladeECS 1.x). The condition is never selected by ref name.
import FirebladeECS

// The minimal entity of the matrix carries two components (first, second); the mixed lookup workload adds a third.
// Initializer shape `init(value:)` is the same in both models, so shared code never branches on the model.
#if ECS_CLASS_COMPONENTS
/// Class-component revision (`Component: AnyObject`) with its single, default storage.
final class CompatFirstComponent: Component {
    let value: Int
    init(value: Int) { self.value = value }
}

final class CompatSecondComponent: Component {
    let value: Int
    init(value: Int) { self.value = value }
}

final class CompatThirdComponent: Component {
    let value: Int
    init(value: Int) { self.value = value }
}
#else
/// Value-component revision (`Component: Sendable`) with selectable storage backends.
struct CompatFirstComponent: Component, Sendable {
    var value: Int
}

struct CompatSecondComponent: Component, Sendable {
    var value: Int
}

struct CompatThirdComponent: Component, Sendable {
    var value: Int
}
#endif

enum CompatSuite {
    #if ECS_CLASS_COMPONENTS
    static let usesClassComponents = true
    static let componentModel = "class"
    static let backends = ["default"]

    static func makeNexus(backend _: String) -> Nexus {
        Nexus()
    }
    #else
    static let usesClassComponents = false
    static let componentModel = "value"
    static let backends = ["archetype", "sparseSet"]

    static func makeNexus(backend: String) -> Nexus {
        switch backend {
        case "archetype": Nexus(storage: .archetype)
        case "sparseSet": Nexus(storage: .sparseSet)
        default: preconditionFailure("unknown backend \(backend)")
        }
    }
    #endif
}
