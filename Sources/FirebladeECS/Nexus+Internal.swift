//
//  Nexus+Internal.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

extension Nexus {
    /// Reports a mutation through a handle of an entity that is destroyed.
    ///
    /// Notifies the delegate and stops with an assertion failure in debug builds, naming the stale and the current version of the slot.
    /// - Parameter entityId: The stale identifier.
    @usableFromInline
    func reportStaleHandle(_ entityId: EntityIdentifier) {
        let current = backend.currentEntity(atIndex: entityId.index)
        let message = "stale handle \(entityId), " + (current.map { "slot is at \($0)" } ?? "slot is free")
        delegate?.nexusNonFatalError(message)
        if assertsOnStaleHandles {
            assertionFailure(message)
        }
    }

    /// Assigns a collection of components to an entity.
    ///
    /// - Parameters:
    ///   - components: The components to assign.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if all assignments were successful, `false` if the entity identifier is stale. A component of a type the entity already has is replaced.
    @usableFromInline
    @discardableResult
    func assign(components: some Collection<Component>, to entityId: EntityIdentifier) -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        var iter = components.makeIterator()
        while let component = iter.next() {
            // a delegate notified about the previous component may have destroyed the entity
            guard isAlive(entityId) else {
                delegate?.nexusNonFatalError("ComponentAdd failure: \(entityId) was destroyed while its components were assigned")
                return false
            }
            guard insert(component, entityId) else {
                return false
            }
        }

        // Update entity membership
        update(familyMembership: entityId)
        return true
    }

    /// Assigns multiple components to an entity, replacing components of types it already has.
    ///
    /// - Parameters:
    ///   - components: The components to assign.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if all assignments were successful, `false` otherwise.
    func assign<each C: Component>(components: repeat each C, entityId: EntityIdentifier) -> Bool {
        var success = true
        _ = (repeat (success = success && assign(component: each components, entityId: entityId)))
        return success
    }

    /// Assigns a single component to an entity.
    ///
    /// - Parameters:
    ///   - component: The component to assign.
    ///   - entityId: The identifier of the entity.
    /// - Returns: `true` if the assignment was successful, `false` otherwise.
    @usableFromInline
    func assign(component: Component, entityId: EntityIdentifier) -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        guard insert(component, entityId) else {
            return false
        }

        // Update entity membership
        update(familyMembership: entityId)
        return true
    }

    /// Inserts a component instance into the storage of its type, or replaces the one the entity has.
    ///
    /// Delivers ``ComponentAdded`` for a new component and ``ComponentReplaced`` (to delegates subscribed to value
    /// changes) when it replaced one. Either way the entity ends up with exactly this value.
    ///
    /// - Parameters:
    ///   - component: The component instance. Its type selects the storage.
    ///   - entityId: The identifier of the living entity.
    /// - Returns: `true`, the entity has the component afterwards.
    @usableFromInline
    func insert<C: Component>(_ component: C, _ entityId: EntityIdentifier) -> Bool {
        let componentIndex = C.componentIndex
        let replaces = backend.has(componentIndex: componentIndex, for: entityId)
        if !replaces, !backend.hasStorage(for: componentIndex) {
            registerOnFirstAssignment(C.self)
        }
        // adds the component to its storage and the component type to the entity's component set, or overwrites it
        backend.set(component, at: componentIndex, for: entityId)
        if replaces {
            emitReplaced(C.self, for: entityId)
        } else {
            delegate?.nexusEvent(ComponentAdded(component: C.identifier, toEntity: entityId))
        }
        return true
    }

    /// Updates family membership for a specific entity across all families.
    ///
    /// - Parameter entityId: The identifier of the entity to update.
    @usableFromInline
    func update(familyMembership entityId: EntityIdentifier) {
        // FIXME: iterating all families is costly for many families
        // FIXME: this could be parallelized
        guard let mask = backend.componentMask(of: entityId) else {
            // not alive - so skip
            return
        }
        for family in familyList {
            update(membership: family.traits, filter: family.filter, mask: mask, for: entityId)
        }
    }

    /// Called when a family is initialized to populate it with existing matching entities.
    ///
    /// - Parameters:
    ///   - traits: The traits defining the family.
    ///   - filter: The membership predicate of the family.
    func onFamilyInit(traits: FamilyTraitSet, filter: FamilyFilter) {
        guard familyMembersByTraits[traits] == nil else {
            return
        }

        familyMembersByTraits[traits] = UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Index>()
        familyFiltersByTraits[traits] = filter
        familyList.append((traits, filter))
        // FIXME: iterating all entities is costly for many entities
        // The identifiers ascend by slot index, which makes the member order deterministic instead of following a hash seed.
        for entityId in backend.livingEntityIds {
            if let mask = backend.componentMask(of: entityId) {
                update(membership: traits, filter: filter, mask: mask, for: entityId)
            }
        }
    }

    /// Updates membership for a specific family and entity.
    ///
    /// Checks if the entity matches the family filter and adds/removes it accordingly.
    ///
    /// - Parameters:
    ///   - traits: The traits defining the family.
    ///   - filter: The membership predicate of the family.
    ///   - mask: The component set of the entity.
    ///   - entityId: The identifier of the entity.
    func update(membership traits: FamilyTraitSet, filter: FamilyFilter, mask: ComponentMask, for entityId: EntityIdentifier) {
        let isMember: Bool = isMember(entity: entityId, inFamilyWithTraits: traits)
        let isMatch: Bool = filter.accepts(mask)

        switch (isMatch, isMember) {
        case (true, false):
            add(entityWithId: entityId, toFamilyWithTraits: traits)
            delegate?.nexusEvent(FamilyMemberAdded(member: entityId, toFamily: traits))

        case (false, true):
            remove(entityWithId: entityId, fromFamilyWithTraits: traits)
            delegate?.nexusEvent(FamilyMemberRemoved(member: entityId, from: traits))

        default:
            break
        }
    }

    /// Adds an entity to a family.
    ///
    /// - Parameters:
    ///   - entityId: The identifier of the entity.
    ///   - traits: The traits defining the family.
    func add(entityWithId entityId: EntityIdentifier, toFamilyWithTraits traits: FamilyTraitSet) {
        familyMembersByTraits[traits].unsafelyUnwrapped.insert(entityId, at: entityId.index)
    }

    /// Removes an entity from a family.
    ///
    /// - Parameters:
    ///   - entityId: The identifier of the entity.
    ///   - traits: The traits defining the family.
    func remove(entityWithId entityId: EntityIdentifier, fromFamilyWithTraits traits: FamilyTraitSet) {
        familyMembersByTraits[traits].unsafelyUnwrapped.remove(at: entityId.index)
    }
}
