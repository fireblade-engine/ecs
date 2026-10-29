// Workloads shared verbatim by every FirebladeECS revision. Stable identities are the contract with the plan's matrix.
import Benchmark
import FirebladeECS

/// How closely a workload follows its upstream (`abeimler/ecs_benchmark`) counterpart. Machine-readable via `note`.
enum CompatParity: Equatable, Sendable {
    case equivalent
    case adapted(String)

    /// `equivalent` or `adapted(<reason>)`.
    var note: String {
        switch self {
        case .equivalent: "equivalent"
        case let .adapted(reason): "adapted(\(reason))"
        }
    }
}

/// Counts reported by one timed pass; the benchmark consumes it, the tests assert on it.
struct CompatOutcome: Equatable {
    /// Timed operations performed (entities created or destroyed, lookups, remove/add pairs, additions).
    var operations = 0
    /// Operations that changed what they targeted (successful destroys, completed remove/add pairs, additions); zero for
    /// lookups, whose results go to `blackHole` and are verified by the tests with direct reads.
    var hits = 0
    /// Sum of the component values written by mutation workloads.
    var valueSum = 0
}

/// A family built during setup. `matched` is the family's member count at preparation; `visit` runs one full pass and returns
/// the number of members it visited (kept distinct from the number of entities created).
struct CompatFamilyProbe {
    let matched: Int
    let visit: () -> Int
}

/// Untimed state of one invocation. Every invocation prepares a fresh state, so warmup and repeated runs do the same work.
struct CompatState {
    let nexus: Nexus
    /// Family prepared before timing, for iteration workloads.
    var family: CompatFamilyProbe?
    /// Persistent world of update and event workloads.
    var runner: (any CompatPassRunner)?
    /// Entities the timed pass acts on (empty for creation workloads).
    var entities: [Entity]
}

enum CompatWorkload: String, CaseIterable, Sendable {
    case createNoEntities = "entity.create.no-entities"
    case createEmpty = "entity.create.empty"
    case createMinimal = "entity.create.minimal"
    case destroyMinimal = "entity.destroy.minimal"
    case lookupNone = "entity.lookup.none"
    case lookupOne = "entity.lookup.one"
    case lookupTwo = "entity.lookup.two"
    case lookupMixedThree = "entity.lookup.mixed-three"
    case iterationOne = "iteration.one"
    case iterationTwo = "iteration.two"
    case iterationMixedThree = "iteration.mixed-three"
    case removeAdd = "component.remove-add"
    case add = "component.add"
    case systemBasicUniform = "system.update.basic.uniform"
    case systemBasicMixed = "system.update.basic.mixed"
    case systemComplexUniform = "system.update.complex.uniform"
    case systemComplexMixed = "system.update.complex.mixed"
    case eventPublishMixed = "event.component.publish.mixed"
    case eventPublishUpdateMixed = "event.component.publish-update.mixed"

    /// Scales shared by every scaled workload. `smallScale` is what smoke selections use.
    static let scales = [0, 1, 16, 1024]
    static let smallScale = 16

    /// Scales this workload is registered at. `entity.create.no-entities` creates zero entities whatever the scale, so it is
    /// registered once, at scale 0 (which the default smoke filter selects explicitly).
    var registeredScales: [Int] {
        self == .createNoEntities ? [0] : Self.scales
    }

    /// Stable matrix identity.
    var identity: String { rawValue }

    /// Name of the upstream benchmark this workload follows.
    var upstreamName: String {
        switch self {
        case .createNoEntities: "CreateNoEntities"
        case .createEmpty: "CreateEmptyEntities"
        case .createMinimal: "CreateEntities"
        case .destroyMinimal: "DestroyEntities"
        case .lookupNone: "UnpackNoComponent"
        case .lookupOne: "UnpackOneComponent"
        case .lookupTwo: "UnpackTwoComponents"
        case .lookupMixedThree: "UnpackThreeComponents"
        case .iterationOne: "IterateSingleComponent"
        case .iterationTwo: "IterateTwoComponents"
        case .iterationMixedThree: "IterateThreeComponentsWithMixedEntities"
        case .removeAdd: "RemoveAddComponent"
        case .add: "AddComponent"
        case .systemBasicUniform: "SystemsUpdate"
        case .systemBasicMixed: "SystemsUpdateMixedEntities"
        case .systemComplexUniform: "ComplexSystemsUpdate"
        case .systemComplexMixed: "ComplexSystemsUpdateMixedEntities"
        case .eventPublishMixed: "PublishEventsViaComponentWithMixedEntities"
        case .eventPublishUpdateMixed: "PublishAndUpdateEventsViaComponentWithMixedEntities"
        }
    }

    /// Update and event workloads keep one world across passes and invocations (upstream does not reset between passes), so
    /// their benchmarks build it in the benchmark setup phase instead of per invocation.
    var persistsState: Bool {
        switch self {
        case .systemBasicUniform, .systemBasicMixed, .systemComplexUniform, .systemComplexMixed,
             .eventPublishMixed, .eventPublishUpdateMixed:
            true
        default:
            false
        }
    }

    var parity: CompatParity {
        switch self {
        case .createNoEntities, .createEmpty, .createMinimal, .destroyMinimal:
            .adapted("nexus teardown is outside the timed region; upstream times registry teardown")
        case .lookupNone, .lookupOne, .lookupTwo:
            .equivalent
        case .lookupMixedThree:
            .adapted("population and lookup count match; payload is a single Int per component and gets return the component")
        case .iterationOne, .iterationTwo:
            .adapted("access differs by component model (value copies on value revisions, class references on 1.x); family built before timing; upstream boundary varies by wrapper")
        case .iterationMixedThree:
            .adapted("membership recipe matches upstream; access differs by component model (value copies vs class references); family built before timing")
        case .removeAdd:
            .equivalent
        case .add:
            .adapted("component one is removed from the whole batch before timing; upstream pauses to remove per entity")
        case .systemBasicUniform, .systemBasicMixed:
            .adapted("two-system set (movement, data) and population ported from the local reference update benchmark, upstream app composition unverified; value revisions write components back with set, class revisions mutate in place")
        case .systemComplexUniform, .systemComplexMixed:
            .adapted("seven-system set follows the local Update7SystemsOnly composition, upstream composition unverified; same population as the basic workloads; value revisions write components back with set, class revisions mutate in place")
        case .eventPublishMixed:
            .adapted("per-entity marker add then per-entity remove; no native type-wide component clear")
        case .eventPublishUpdateMixed:
            .adapted("effective upstream workload: Position+Velocity update, empty marker view visits zero, per-entity clear of an empty marker pool; no native type-wide component clear")
        }
    }

    /// Benchmark name: identity, backend, scale. The identity is the prefix before the first space.
    func benchmarkName(backend: String, scale: Int) -> String {
        "\(identity) [\(backend)] / \(scale)"
    }

    /// Unpaused setup: builds the state the timed pass acts on. Never part of the timed region.
    func prepare(backend: String, count: Int) -> CompatState {
        let nexus = CompatSuite.makeNexus(backend: backend)
        var entities: [Entity] = []
        switch self {
        case .createNoEntities, .createEmpty, .createMinimal:
            break
        case .destroyMinimal, .lookupOne, .lookupTwo, .removeAdd:
            entities = Self.makeMinimalEntities(in: nexus, count: count)
        case .lookupNone:
            entities = (0 ..< count).map { _ in nexus.createEntity() }
        case .lookupMixedThree:
            // Even indices carry all three components and are the lookup targets; odd indices carry two and are not looked up.
            entities.reserveCapacity((count + 1) / 2)
            for index in 0 ..< count {
                if index.isMultiple(of: 2) {
                    entities.append(nexus.createEntity(
                        with: CompatFirstComponent(value: index),
                        CompatSecondComponent(value: index * 2),
                        CompatThirdComponent(value: index * 3)
                    ))
                } else {
                    nexus.createEntity(with: CompatFirstComponent(value: index), CompatSecondComponent(value: index * 2))
                }
            }
        case .add:
            entities = Self.makeMinimalEntities(in: nexus, count: count)
            for entity in entities {
                entity.remove(CompatFirstComponent.self)
            }
        case .systemBasicUniform, .systemBasicMixed, .systemComplexUniform, .systemComplexMixed:
            let isMixed = self == .systemBasicMixed || self == .systemComplexMixed
            CompatPopulation.populate(nexus: nexus, entityCount: count, isMixed: isMixed)
            let isComplex = self == .systemComplexUniform || self == .systemComplexMixed
            return CompatState(nexus: nexus, runner: CompatUpdateWorld(nexus: nexus, isComplex: isComplex), entities: [])
        case .eventPublishMixed, .eventPublishUpdateMixed:
            CompatPopulation.populate(nexus: nexus, entityCount: count, isMixed: true)
            return CompatState(nexus: nexus, runner: CompatEventWorld(nexus: nexus, withUpdate: self == .eventPublishUpdateMixed), entities: [])
        case .iterationOne:
            for index in 0 ..< count {
                nexus.createEntity(with: CompatFirstComponent(value: index))
            }
            let family = nexus.family(requires: CompatFirstComponent.self)
            return CompatState(nexus: nexus, family: CompatFamilyProbe(matched: family.count) {
                var visited = 0
                for first in family {
                    blackHole(first)
                    visited += 1
                }
                return visited
            }, entities: [])
        case .iterationTwo:
            _ = Self.makeMinimalEntities(in: nexus, count: count)
            let family = nexus.family(requiresAll: CompatFirstComponent.self, CompatSecondComponent.self)
            return CompatState(nexus: nexus, family: CompatFamilyProbe(matched: family.count) {
                var visited = 0
                for (first, second) in family {
                    blackHole(first)
                    blackHole(second)
                    visited += 1
                }
                return visited
            }, entities: [])
        case .iterationMixedThree:
            for index in 0 ..< count {
                let entity = nexus.createEntity(
                    with: CompatFirstComponent(value: index),
                    CompatSecondComponent(value: index * 2),
                    CompatThirdComponent(value: index * 3)
                )
                let removal = Self.mixedThreeRemovals(index: index, count: count)
                if removal.first { entity.remove(CompatFirstComponent.self) }
                if removal.second { entity.remove(CompatSecondComponent.self) }
                if removal.third { entity.remove(CompatThirdComponent.self) }
            }
            let family = nexus.family(requiresAll: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self)
            return CompatState(nexus: nexus, family: CompatFamilyProbe(matched: family.count) {
                var visited = 0
                for (first, second, third) in family {
                    blackHole(first)
                    blackHole(second)
                    blackHole(third)
                    visited += 1
                }
                return visited
            }, entities: [])
        }
        return CompatState(nexus: nexus, entities: entities)
    }

    /// The timed pass: exactly one pass over `count` (creation) or over the prepared entities.
    func run(_ state: CompatState, count: Int) -> CompatOutcome {
        var outcome = CompatOutcome()
        let nexus = state.nexus
        switch self {
        case .createNoEntities:
            // Always zero, independent of the scale label; distinct from createEmpty at count 0 in identity and intent.
            for _ in 0 ..< 0 {
                nexus.createEntity()
                outcome.operations += 1
            }
        case .createEmpty:
            for _ in 0 ..< count {
                nexus.createEntity()
                outcome.operations += 1
            }
            outcome.hits = outcome.operations
        case .createMinimal:
            for index in 0 ..< count {
                nexus.createEntity(with: CompatFirstComponent(value: index), CompatSecondComponent(value: index * 2))
                outcome.operations += 1
            }
            outcome.hits = outcome.operations
        case .destroyMinimal:
            for entity in state.entities {
                outcome.operations += 1
                if nexus.destroy(entity: entity) { outcome.hits += 1 }
            }
        case .lookupNone:
            // Results go to blackHole like the upstream locals; counts are derived, not tracked per lookup.
            for entity in state.entities {
                blackHole(entity.get(CompatThirdComponent.self))
            }
            outcome.operations = state.entities.count
        case .lookupOne:
            for entity in state.entities {
                blackHole(entity.get(CompatFirstComponent.self))
            }
            outcome.operations = state.entities.count
        case .lookupTwo:
            for entity in state.entities {
                // Two separate gets per entity, as upstream.
                blackHole(entity.get(CompatFirstComponent.self))
                blackHole(entity.get(CompatSecondComponent.self))
            }
            outcome.operations = state.entities.count * 2
        case .lookupMixedThree:
            for entity in state.entities {
                let (first, second, third) = entity.get(
                    components: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self
                )
                blackHole(first)
                blackHole(second)
                blackHole(third)
            }
            outcome.operations = state.entities.count * 3
        case .iterationOne, .iterationTwo, .iterationMixedThree:
            outcome.operations = state.family?.visit() ?? 0
        case .systemBasicUniform, .systemBasicMixed, .systemComplexUniform, .systemComplexMixed,
             .eventPublishMixed, .eventPublishUpdateMixed:
            outcome = state.runner?.pass() ?? outcome
        case .removeAdd:
            for (index, entity) in state.entities.enumerated() {
                outcome.operations += 1
                // `remove` returns Bool on value revisions and Entity on 1.x, so the result is not used; a completed
                // remove/add pair counts as one hit and the tests verify occupancy.
                entity.remove(CompatFirstComponent.self)
                entity.set(CompatFirstComponent(value: index))
                outcome.hits += 1
                outcome.valueSum &+= index
            }
        case .add:
            for (index, entity) in state.entities.enumerated() {
                outcome.operations += 1
                entity.set(CompatFirstComponent(value: index))
                outcome.hits += 1
                outcome.valueSum &+= index
            }
        }
        return outcome
    }

    /// Upstream removal recipe of the mixed three-component iteration: all indices are eligible below 100 entities, otherwise
    /// the inclusive band `[floor(N/2), floor(3N/4)]` and every tenth ordinal in it; component one/two/three is removed when the
    /// index is divisible by 7/11/13.
    static func mixedThreeRemovals(index: Int, count: Int) -> (first: Bool, second: Bool, third: Bool) {
        let start = 2 * count / 4
        let end = 3 * count / 4
        let eligible = count < 100 || (index >= start && index <= end)
        let removes = eligible && (count < 100 || (index - start) % 10 == 0)
        return (removes && index % 7 == 0, removes && index % 11 == 0, removes && index % 13 == 0)
    }

    private static func makeMinimalEntities(in nexus: Nexus, count: Int) -> [Entity] {
        (0 ..< count).map { index in
            nexus.createEntity(with: CompatFirstComponent(value: index), CompatSecondComponent(value: index * 2))
        }
    }
}

/// A reference workload with no applicable native operation on either revision. Step 8 emits these next to the results.
struct CompatUnsupported: Equatable, Sendable {
    let identity: String
    let upstreamName: String
    let reason: String

    static let nativeBulk = "no native bulk operation; createEntities(count:) loops over per-entity creation and Family.destroyMembers destroys entity by entity"
    static let dispatcher = "no arbitrary-event dispatcher or queue API"
    static let observer = "no arbitrary-event observer or emit API; Nexus events are structural only"
    static let receiver = "no arbitrary-event receiver or event-bus API"

    static let all: [CompatUnsupported] = [
        .init(identity: "entity.create.empty-bulk", upstreamName: "CreateEmptyEntitiesInBulk", reason: nativeBulk),
        .init(identity: "entity.create.minimal-bulk", upstreamName: "CreateEntitiesInBulk", reason: nativeBulk),
        .init(identity: "entity.destroy.minimal-bulk", upstreamName: "DestroyEntitiesInBulk", reason: nativeBulk),
        .init(identity: "event.dispatch.enqueue-update.mixed", upstreamName: "EnqueueAndUpdateEventsViaDispatcherWithMixedEntities", reason: dispatcher),
        .init(identity: "event.dispatch.enqueue-only.mixed", upstreamName: "EnqueueEventsViaDispatcherWithMixedEntities", reason: dispatcher),
        .init(identity: "event.dispatch.update-only.mixed", upstreamName: "UpdateEventsViaDispatcherWithMixedEntities", reason: dispatcher),
        .init(identity: "event.dispatch.trigger-update.mixed", upstreamName: "TriggerAndUpdateEventsViaDispatcherWithMixedEntities", reason: dispatcher),
        .init(identity: "event.observer.enqueue-update.mixed", upstreamName: "EnqueueAndUpdateEventsViaObserverWithMixedEntities", reason: observer),
        .init(identity: "event.observer.emit-update.mixed", upstreamName: "EmitAndUpdateEventsViaObserverWithMixedEntities", reason: observer),
        .init(identity: "event.receiver.post-update.mixed", upstreamName: "PostAndUpdateEventsViaReceiverWithMixedEntities", reason: receiver)
    ]
}
