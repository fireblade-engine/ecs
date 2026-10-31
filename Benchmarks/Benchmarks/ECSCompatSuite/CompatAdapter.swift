// Per-revision adapter of the shared compatibility suite. Everything that differs between FirebladeECS revisions
// lives here; the workloads in CompatWorkloads.swift compile unchanged against every revision.
//
// ECS_CLASS_COMPONENTS is set by Scripts/benchmark-snapshot.sh when the snapshot declares
// `protocol Component: AnyObject` (FirebladeECS 1.x). The condition is never selected by ref name.
import FirebladeECS
#if !ECS_CLASS_COMPONENTS
    import FirebladeECSMacros
#endif

// The minimal entity of the matrix carries two components (first, second); the mixed lookup workload adds a third.
// Initializer shape `init(value:)` is the same in both models, so shared code never branches on the model.
#if ECS_CLASS_COMPONENTS
    /// Class-component revision (`Component: AnyObject`) with its single, default storage.
    final class CompatFirstComponent: Component {
        let value: Int
        init(value: Int) {
            self.value = value
        }
    }

    final class CompatSecondComponent: Component {
        let value: Int
        init(value: Int) {
            self.value = value
        }
    }

    final class CompatThirdComponent: Component {
        let value: Int
        init(value: Int) {
            self.value = value
        }
    }
#else
    /// Value-component revision (`Component: Sendable`) with selectable storage backends, declared with `@Component`
    /// (stored `static let componentIndex`, the documented fast path). Class revisions use plain class conformance.
    @Component
    struct CompatFirstComponent: Component, Sendable {
        var value: Int
    }

    @Component
    struct CompatSecondComponent: Component, Sendable {
        var value: Int
    }

    @Component
    struct CompatThirdComponent: Component, Sendable {
        var value: Int
    }
#endif

/// Boxes a plain payload as a component. Shared code mutates payloads only through the `CompatSuite.forEach*` helpers, so it
/// never branches on the model: class revisions mutate the shared instance, value revisions write the modified copy back.
protocol CompatBoxed: Component {
    associatedtype Payload: Sendable
    var payload: Payload { get set }
    init(_ payload: Payload)
}

#if ECS_CLASS_COMPONENTS
    final class CompatBox<Payload: Sendable>: Component, CompatBoxed, @unchecked Sendable {
        var payload: Payload
        init(_ payload: Payload) {
            self.payload = payload
        }
    }
#else
    struct CompatBox<Payload: Sendable>: Component, CompatBoxed, Sendable {
        var payload: Payload
        init(_ payload: Payload) {
            self.payload = payload
        }
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

        /// Sets `component`, replacing an existing instance (`Entity.set` keeps the existing one on 1.x).
        static func replace(_ component: some Component, on entity: Entity) {
            // 1.4.3 traps when removing a component the entity does not have.
            if entity.has(type(of: component)) {
                entity.remove(type(of: component))
            }
            entity.set(component)
        }

        /// Native family iteration of the class-component revision: plain iteration over the family; written components are
        /// references mutated in place, so nothing is written back. Families are declared with the read types first.
        @inline(__always)
        static func forEachReading<R: Component>(_ family: Family<R>, _ body: (R) -> Void) {
            for r in family {
                body(r)
            }
        }

        @inline(__always)
        static func forEachReading<R1: Component, R2: Component>(_ family: Family<R1, R2>, _ body: (R1, R2) -> Void) {
            for (r1, r2) in family {
                body(r1, r2)
            }
        }

        @inline(__always)
        static func forEachReading<R1: Component, R2: Component, R3: Component>(_ family: Family<R1, R2, R3>, _ body: (R1, R2, R3) -> Void) {
            for (r1, r2, r3) in family {
                body(r1, r2, r3)
            }
        }

        @inline(__always)
        static func forEachWriting<W: Component>(_ family: Family<W>, _ body: (inout W) -> Void) {
            for w in family {
                var w = w
                body(&w)
            }
        }

        @inline(__always)
        static func forEachRead1Write1<R: Component, W: Component>(_ family: Family<R, W>, _ body: (R, inout W) -> Void) {
            for (r, w) in family {
                var w = w
                body(r, &w)
            }
        }

        @inline(__always)
        static func forEachRead1Write2<R: Component, W1: Component, W2: Component>(
            _ family: Family<R, W1, W2>, _ body: (R, inout W1, inout W2) -> Void
        ) {
            for (r, w1, w2) in family {
                var w1 = w1
                var w2 = w2
                body(r, &w1, &w2)
            }
        }

        @inline(__always)
        static func forEachRead2Write1<R1: Component, R2: Component, W: Component>(
            _ family: Family<R1, R2, W>, _ body: (R1, R2, inout W) -> Void
        ) {
            for (r1, r2, w) in family {
                var w = w
                body(r1, r2, &w)
            }
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

        /// Sets `component`, replacing an existing instance.
        static func replace(_ component: some Component, on entity: Entity) {
            entity.set(component)
        }

        /// Native family iteration of the value-component revision: Family.forEach(reading:writing:) with inout written components
        /// (Sources/FirebladeECS/Family+ReadWrite.swift). Families are declared with the read types first.
        @inline(__always)
        static func forEachReading<R: Component>(_ family: Family<R>, _ body: (R) -> Void) {
            family.forEach(reading: R.self, body)
        }

        @inline(__always)
        static func forEachReading<R1: Component, R2: Component>(_ family: Family<R1, R2>, _ body: (R1, R2) -> Void) {
            family.forEach(reading: R1.self, R2.self, body)
        }

        @inline(__always)
        static func forEachReading<R1: Component, R2: Component, R3: Component>(_ family: Family<R1, R2, R3>, _ body: (R1, R2, R3) -> Void) {
            family.forEach(reading: R1.self, R2.self, R3.self, body)
        }

        @inline(__always)
        static func forEachWriting<W: Component>(_ family: Family<W>, _ body: (inout W) -> Void) {
            family.forEach(writing: W.self, body)
        }

        @inline(__always)
        static func forEachRead1Write1<R: Component, W: Component>(_ family: Family<R, W>, _ body: (R, inout W) -> Void) {
            family.forEach(reading: R.self, writing: W.self, body)
        }

        @inline(__always)
        static func forEachRead1Write2<R: Component, W1: Component, W2: Component>(
            _ family: Family<R, W1, W2>, _ body: (R, inout W1, inout W2) -> Void
        ) {
            family.forEach(reading: R.self, writing: W1.self, W2.self, body)
        }

        @inline(__always)
        static func forEachRead2Write1<R1: Component, R2: Component, W: Component>(
            _ family: Family<R1, R2, W>, _ body: (R1, R2, inout W) -> Void
        ) {
            family.forEach(reading: R1.self, R2.self, writing: W.self, body)
        }
    #endif
}
