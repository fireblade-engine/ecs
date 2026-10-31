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
    /// Operations that succeeded: successful destroys, completed remove/add pairs, additions, and lookups that returned a
    /// component (counted per get in the loop).
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

/// Untimed state. Workloads with `persistsState` prepare it once per benchmark and reuse it across iterations; the others
/// prepare a fresh state before every iteration.
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

    /// Upstream's `CreateRange(0, 2'097'152, 2)`: 0 and every power of two up to the maximum (Google Benchmark `AddRange`),
    /// derived rather than listed. `smallScale` is what smoke selections use.
    static let maximumScale = 2_097_152
    static let scales: [Int] = [0] + Array(sequence(first: 1) { $0 < maximumScale ? $0 * 2 : nil })
    static let smallScale = 16

    /// Scales this workload is registered at. `entity.create.no-entities` creates zero entities whatever the scale, so it is
    /// registered once, at scale 0 (which the default smoke filter selects explicitly).
    var registeredScales: [Int] {
        self == .createNoEntities ? [0] : Self.scales
    }

    /// Stable matrix identity.
    var identity: String {
        rawValue
    }

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

    /// Upstream builds these workloads' state once before the timed loop and keeps it across iterations, so the benchmark
    /// prepares it once in the benchmark setup and releases it in teardown. The others pause timing and rebuild state per
    /// iteration upstream (`entity.create.*`, `entity.destroy.minimal`, `component.add`), so here too.
    var persistsState: Bool {
        switch self {
        case .createNoEntities, .createEmpty, .createMinimal, .destroyMinimal, .add:
            false
        default:
            true
        }
    }

    /// Update and event workloads additionally run their passes through a stateful runner.
    var usesRunner: Bool {
        switch self {
        case .systemBasicUniform, .systemBasicMixed, .systemComplexUniform, .systemComplexMixed,
             .eventPublishMixed, .eventPublishUpdateMixed:
            true
        default:
            false
        }
    }

    /// Shared sampling note: the package budget includes untimed setup and has no minimum iteration count.
    private static let perIterationSetupNote = "per-iteration untimed setup counts against the package's 0.5 s wall budget, so measured time and sample count are below upstream's 0.5 s of measured time, especially at large scales"
    private static let declarationNote = "component types are declared with @Component (stored static componentIndex) on value revisions and by plain class conformance on 1.x; the generic CompatBox stays plain on every revision"

    private static let persistentNote = "state is built once and kept across iterations as upstream; sampling is time-based (0.5 s, no warmup) so pass count and world state can differ by revision, as upstream"

    var parity: CompatParity {
        switch self {
        case .createNoEntities, .createEmpty, .createMinimal, .destroyMinimal:
            .adapted("nexus teardown is outside the timed region; upstream times registry teardown; \(Self.perIterationSetupNote)")
        case .lookupNone:
            .adapted("payload is a single Int per component vs upstream float structs; gets return class references on 1.x and value copies on value revisions; the miss is a get of an absent component; entities are created outside timing; \(Self.declarationNote); \(Self.persistentNote)")
        case .lookupOne, .lookupTwo:
            .adapted("payload is a single Int per component vs upstream float structs; gets return class references on 1.x and value copies on value revisions; two separate gets per entity for lookupTwo; entities are created outside timing; \(Self.declarationNote); \(Self.persistentNote)")
        case .lookupMixedThree:
            .adapted("population and lookup count match; payload is a single Int per component and gets return the component; \(Self.declarationNote); \(Self.persistentNote)")
        case .iterationOne, .iterationTwo:
            .adapted("each revision uses its native family iteration (forEach(reading:) value copies on value revisions, plain iteration over class references on 1.x); family built before timing; upstream boundary varies by wrapper; \(Self.persistentNote)")
        case .iterationMixedThree:
            .adapted("membership recipe matches upstream; each revision uses its native family iteration (value copies vs class references); family built before timing; \(Self.persistentNote)")
        case .removeAdd:
            .adapted("payload is a single Int vs upstream float structs; every set allocates a new class instance on 1.x vs a value copy on value revisions; nexus teardown is outside the timed region; every pass returns the entities to their initial occupancy; \(Self.declarationNote); \(Self.persistentNote)")
        case .add:
            .adapted("component one is removed from the whole batch before timing; upstream pauses to remove per entity; \(Self.perIterationSetupNote)")
        case .systemBasicUniform, .systemBasicMixed:
            .adapted("system list (Movement, Data), order and formulas follow upstream; player RNG seeds are ordinal, not address-derived; each revision uses its native family iteration instead of upstream's virtual system dispatch; \(Self.persistentNote)")
        case .systemComplexUniform, .systemComplexMixed:
            .adapted("system list (Movement, Data, MoreComplex, Health, Damage, Sprite, Render), order and formulas follow upstream UseMoreComplexSystems; player RNG seeds are ordinal, not address-derived; each revision uses its native family iteration instead of upstream's virtual system dispatch; \(Self.persistentNote)")
        case .eventPublishMixed:
            .adapted("base-only mixed population (Position, Velocity, Data; no players) as upstream's EnTT factory; per-entity marker add then per-entity remove through a scratch array that is collected inside the timed region; no native type-wide component clear; \(Self.persistentNote)")
        case .eventPublishUpdateMixed:
            .adapted("base-only mixed population (no players) as upstream's EnTT factory; effective upstream workload: Position+Velocity update, empty marker view visits zero, per-entity clear of an empty marker pool via a scratch array collected inside the timed region; no native type-wide component clear; \(Self.persistentNote)")
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
            // Upstream builds events on the base factory's mixed population (no hero/monster components).
            CompatPopulation.populateBaseMixed(nexus: nexus, entityCount: count)
            return CompatState(nexus: nexus, runner: CompatEventWorld(nexus: nexus, withUpdate: self == .eventPublishUpdateMixed), entities: [])
        case .iterationOne:
            for index in 0 ..< count {
                nexus.createEntity(with: CompatFirstComponent(value: index))
            }
            let family = nexus.family(requires: CompatFirstComponent.self)
            return CompatState(nexus: nexus, family: CompatFamilyProbe(matched: family.count) {
                var visited = 0
                CompatSuite.forEachReading(family) { first in
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
                CompatSuite.forEachReading(family) { first, second in
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
                if removal.first {
                    entity.remove(CompatFirstComponent.self)
                }
                if removal.second {
                    entity.remove(CompatSecondComponent.self)
                }
                if removal.third {
                    entity.remove(CompatThirdComponent.self)
                }
            }
            let family = nexus.family(requiresAll: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self)
            return CompatState(nexus: nexus, family: CompatFamilyProbe(matched: family.count) {
                var visited = 0
                CompatSuite.forEachReading(family) { first, second, third in
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
                if nexus.destroy(entity: entity) {
                    outcome.hits += 1
                }
            }
        case .lookupNone:
            // Results go to blackHole like the upstream locals; each get is counted, successful ones as hits.
            for entity in state.entities {
                let third = entity.get(CompatThirdComponent.self)
                blackHole(third)
                outcome.operations += 1
                if third != nil {
                    outcome.hits += 1
                }
            }
        case .lookupOne:
            for entity in state.entities {
                let first = entity.get(CompatFirstComponent.self)
                blackHole(first)
                outcome.operations += 1
                if first != nil {
                    outcome.hits += 1
                }
            }
        case .lookupTwo:
            for entity in state.entities {
                // Two separate gets per entity, as upstream.
                let first = entity.get(CompatFirstComponent.self)
                blackHole(first)
                let second = entity.get(CompatSecondComponent.self)
                blackHole(second)
                outcome.operations += 2
                if first != nil {
                    outcome.hits += 1
                }
                if second != nil {
                    outcome.hits += 1
                }
            }
        case .lookupMixedThree:
            for entity in state.entities {
                let (first, second, third) = entity.get(
                    components: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self
                )
                blackHole(first)
                blackHole(second)
                blackHole(third)
                outcome.operations += 3
                if first != nil {
                    outcome.hits += 1
                }
                if second != nil {
                    outcome.hits += 1
                }
                if third != nil {
                    outcome.hits += 1
                }
            }
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
