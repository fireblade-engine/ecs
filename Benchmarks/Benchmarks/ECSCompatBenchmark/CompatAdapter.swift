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

/// Boxes a plain payload as a component. Shared code mutates payloads only through `CompatSuite.modify`, so it never branches
/// on the model: class revisions mutate the shared instance, value revisions write the modified copy back.
protocol CompatBoxed: Component {
    associatedtype Payload: Sendable
    var payload: Payload { get set }
    init(_ payload: Payload)
}

#if ECS_CLASS_COMPONENTS
final class CompatBox<Payload: Sendable>: Component, CompatBoxed, @unchecked Sendable {
    var payload: Payload
    init(_ payload: Payload) { self.payload = payload }
}
#else
struct CompatBox<Payload: Sendable>: Component, CompatBoxed, Sendable {
    var payload: Payload
    init(_ payload: Payload) { self.payload = payload }
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

    /// Mutates `component` in place (class components are references; nothing to write back).
    static func modify<C: CompatBoxed>(_ component: C, of _: Entity, _ body: (inout C.Payload) -> Void) {
        var component = component
        body(&component.payload)
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

    /// Mutates a copy of `component` and writes it back to `entity` (value components are copied on read).
    static func modify<C: CompatBoxed>(_ component: C, of entity: Entity, _ body: (inout C.Payload) -> Void) {
        var component = component
        body(&component.payload)
        entity.set(component)
    }
    #endif
}
