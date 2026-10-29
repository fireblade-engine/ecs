// Workloads shared verbatim by every FirebladeECS revision. Stable identities are the contract with the plan's matrix.
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
    /// Operations that found or changed what they targeted (successful destroys, lookups that returned components, removals).
    var hits = 0
    /// Sum of the component values read or written, so lookups produce an observable result.
    var valueSum = 0
}

/// Untimed state of one invocation. Every invocation prepares a fresh state, so warmup and repeated runs do the same work.
struct CompatState {
    let nexus: Nexus
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
    case removeAdd = "component.remove-add"
    case add = "component.add"

    /// Scales shared by every workload. `smallScale` is what smoke selections use.
    static let scales = [0, 1, 16, 1024]
    static let smallScale = 16

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
        case .removeAdd: "RemoveAddComponent"
        case .add: "AddComponent"
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
        case .removeAdd:
            .equivalent
        case .add:
            .adapted("component one is removed from the whole batch before timing; upstream pauses to remove per entity")
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
            for entity in state.entities {
                outcome.operations += 1
                if let third = entity.get(CompatThirdComponent.self) {
                    outcome.hits += 1
                    outcome.valueSum &+= third.value
                }
            }
        case .lookupOne:
            for entity in state.entities {
                outcome.operations += 1
                if let first = entity.get(CompatFirstComponent.self) {
                    outcome.hits += 1
                    outcome.valueSum &+= first.value
                }
            }
        case .lookupTwo:
            for entity in state.entities {
                // Two separate gets per entity, as upstream.
                outcome.operations += 2
                if let first = entity.get(CompatFirstComponent.self) {
                    outcome.hits += 1
                    outcome.valueSum &+= first.value
                }
                if let second = entity.get(CompatSecondComponent.self) {
                    outcome.hits += 1
                    outcome.valueSum &+= second.value
                }
            }
        case .lookupMixedThree:
            for entity in state.entities {
                // Three gets per looked-up entity.
                outcome.operations += 3
                let (first, second, third) = entity.get(
                    components: CompatFirstComponent.self, CompatSecondComponent.self, CompatThirdComponent.self
                )
                if let first { outcome.hits += 1; outcome.valueSum &+= first.value }
                if let second { outcome.hits += 1; outcome.valueSum &+= second.value }
                if let third { outcome.hits += 1; outcome.valueSum &+= third.value }
            }
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

    private static func makeMinimalEntities(in nexus: Nexus, count: Int) -> [Entity] {
        (0 ..< count).map { index in
            nexus.createEntity(with: CompatFirstComponent(value: index), CompatSecondComponent(value: index * 2))
        }
    }
}
