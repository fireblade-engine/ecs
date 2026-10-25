# Reacting to Nexus events

Observe structural changes and, on request, changes of component values.

## Overview

A ``Nexus`` reports what happens to its entities, components and families to its ``Nexus/delegate``.

Structural events are always delivered:

- ``EntityCreated``, ``EntityDestroyed``
- ``ComponentAdded``, ``ComponentRemoved``
- ``FamilyMemberAdded``, ``FamilyMemberRemoved``

Value change events are opt-in:

- ``ComponentReplaced``: a component was set on an entity that already had one of that type.
- ``ComponentModified``: a component of one entity was changed in place.
- ``ComponentsModified``: a bulk write pass changed the components of a type. One event per pass, not one per entity; ``ComponentsModified/count`` is the number of components the pass could write.

Every event names its entity with the generational ``EntityIdentifier``, so a stale identifier never matches a later entity in the same slot.

### Subscribing

``NexusEventDelegate/subscribedEvents`` is ``NexusEventMask/structural`` by default. Return ``NexusEventMask/valueChanges`` or ``NexusEventMask/all`` to receive value changes:

```swift
final class Observer: NexusEventDelegate {
    var subscribedEvents: NexusEventMask { .all }

    func nexusEvent(_ event: NexusEvent) {
        switch event {
        case let added as ComponentAdded:
            print("added", added.component, "to", added.toEntity)
        case let modified as ComponentModified:
            print("modified", modified.component, "of", modified.entityId)
        default:
            break
        }
    }

    func nexusNonFatalError(_ message: String) {}
}

nexus.delegate = observer
```

- ``NexusEvent`` is an open protocol and later releases add events. Always switch with a `default:` case.
- The nexus reads `subscribedEvents` once, when the delegate is assigned. After changing the subscription, assign the delegate again: `nexus.delegate = observer`.
- ``NexusEventMask/structural`` is informational. Structural events are always delivered, as in FirebladeECS 1, also to a delegate whose mask does not contain it.

### Cost

With the default mask a write to a component costs one branch on a flag the nexus caches, and nothing else: the delegate is not called and no event is created.

### Ordering

Modifying a component that is missing, with a default value, delivers ``ComponentAdded`` and then ``ComponentModified``. Setting a component the entity does not have yet delivers ``ComponentAdded`` only, never ``ComponentReplaced``.

In FirebladeECS 2.0 ``ComponentReplaced`` is part of the event set, but assigning a component the entity already has still reports a "ComponentAdd collision" to ``NexusEventDelegate/nexusNonFatalError(_:)`` and keeps the old component, as in FirebladeECS 1.

### Comparison with flecs

flecs observers (OnAdd, OnRemove, OnSet) fire on an actual add or remove, and OnSet fires on every `set` and on an explicit `modified()` call, but not on direct writes through a pointer. Setting a missing component fires OnAdd and then OnSet. Observers cost nothing while none exist.

FirebladeECS differs on purpose: in-place writes through the nexus emit ``ComponentModified`` automatically, so there is no `modified()` call to forget, and setting a missing component emits ``ComponentAdded`` only.
