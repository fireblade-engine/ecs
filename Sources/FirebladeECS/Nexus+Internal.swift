//
//  Nexus+Internal.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

extension Nexus {
    @usableFromInline
    @discardableResult
    func assign(components: some Collection<Component>, to entityId: EntityIdentifier) -> Bool {
        var iter = components.makeIterator()
        while let component = iter.next() {
            let componentId = component.identifier
            // test if component is already assigned
            guard !has(componentId: componentId, entityId: entityId) else {
                delegate?.nexusNonFatalError("ComponentAdd collision: \(entityId) already has a component \(component)")
                assertionFailure("ComponentAdd collision: \(entityId) already has a component \(component)")
                return false
            }

            // add component instances to uniform component stores
            insertComponentInstance(component, componentId, entityId)

            // assigns the component id to the entity id
            assign(componentId, entityId)
        }

        // Update entity membership
        update(familyMembership: entityId)
        return true
    }

    @usableFromInline
    func assign(component: Component, entityId: EntityIdentifier) -> Bool {
        let componentId = component.identifier

        // test if component is already assigned
        guard !has(componentId: componentId, entityId: entityId) else {
            delegate?.nexusNonFatalError("ComponentAdd collision: \(entityId) already has a component \(component)")
            assertionFailure("ComponentAdd collision: \(entityId) already has a component \(component)")
            return false
        }

        // add component instances to uniform component stores
        insertComponentInstance(component, componentId, entityId)

        // assigns the component id to the entity id
        assign(componentId, entityId)

        // Update entity membership
        update(familyMembership: entityId)
        return true
    }

    @usableFromInline
    func insertComponentInstance(_ component: Component, _ componentId: ComponentIdentifier, _ entityId: EntityIdentifier) {
        if componentsByType[componentId] == nil {
            componentsByType[componentId] = ManagedContiguousArray<Component>()
        }
        componentsByType[componentId]?.insert(component, at: entityId.index)
    }

    @usableFromInline
    func assign(_ componentId: ComponentIdentifier, _ entityId: EntityIdentifier) {
        let (inserted, _) = componentIdsByEntity[entityId]!.insert(componentId)
        if inserted {
            delegate?.nexusEvent(ComponentAdded(component: componentId, toEntity: entityId))
        }
    }

    @usableFromInline
    func update(familyMembership entityId: EntityIdentifier) {
        // FIXME: iterating all families is costly for many families
        // FIXME: this could be parallelized
        var iter = familyMembersByTraits.keys.makeIterator()
        while let traits = iter.next() {
            update(membership: traits, for: entityId)
        }
    }

    /// will be called on family init
    func onFamilyInit(traits: FamilyTraitSet) {
        guard familyMembersByTraits[traits] == nil else {
            return
        }

        familyMembersByTraits[traits] = UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Identifier>()
        update(familyMembership: traits)
    }

    func update(familyMembership traits: FamilyTraitSet) {
        // FIXME: iterating all entities is costly for many entities
        var iter = componentIdsByEntity.keys.makeIterator()
        while let entityId = iter.next() {
            update(membership: traits, for: entityId)
        }
    }

    func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
        guard let componentIds = componentIdsByEntity[entityId] else {
            // no components - so skip
            return
        }

        let isMember: Bool = isMember(entity: entityId, inFamilyWithTraits: traits)
        if !exists(entity: entityId), isMember {
            remove(entityWithId: entityId, fromFamilyWithTraits: traits)
            return
        }

        let isMatch: Bool = traits.isMatch(components: componentIds)

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

    func add(entityWithId entityId: EntityIdentifier, toFamilyWithTraits traits: FamilyTraitSet) {
        familyMembersByTraits[traits].unsafelyUnwrapped.insert(entityId, at: entityId.id)
    }

    func remove(entityWithId entityId: EntityIdentifier, fromFamilyWithTraits traits: FamilyTraitSet) {
        familyMembersByTraits[traits].unsafelyUnwrapped.remove(at: entityId.id)
    }
}
