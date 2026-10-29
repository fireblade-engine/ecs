// Per-revision adapter of the shared compatibility suite. Everything that differs between FirebladeECS revisions
// lives here; the workloads in CompatWorkloads.swift compile unchanged against every revision.
//
// ECS_CLASS_COMPONENTS is set by Scripts/benchmark-snapshot.sh when the snapshot declares
// `protocol Component: AnyObject` (FirebladeECS 1.x). The condition is never selected by ref name.
import FirebladeECS

#if ECS_CLASS_COMPONENTS
/// Class-component revision (`Component: AnyObject`) with its single, default storage.
final class CompatProbeComponent: Component {
    var value = 0
}
#else
/// Value-component revision (`Component: Sendable`) with selectable storage backends.
struct CompatProbeComponent: Component, Sendable {
    var value = 0
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
