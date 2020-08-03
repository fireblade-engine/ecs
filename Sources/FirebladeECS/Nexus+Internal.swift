//
//  Nexus+Internal.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 14.02.19.
//

extension Nexus {
    func assign<C>(components: C, to entityId: EntityIdentifier) where C: Collection, C.Element == Component {
        var iter = components.makeIterator()
        while let component = iter.next() {
            let componentId = component.identifier
            // test if component is already assigned
            guard !has(componentId: componentId, entityId: entityId) else {
                delegate?.nexusNonFatalError("ComponentAdd collision: \(entityId) already has a component \(component)")
                assertionFailure("ComponentAdd collision: \(entityId) already has a component \(component)")
                return
            }

            // add component instances to uniform component stores
            insertComponentInstance(component, componentId, entityId)

            // assigns the component id to the entity id
            assign(componentId, entityId)
        }

        // Update entity membership
        update(familyMembership: entityId)
    }

    func assign(component: Component, entityId: EntityIdentifier) {
        let componentId = component.identifier

        // test if component is already assigned
        guard !has(componentId: componentId, entityId: entityId) else {
            delegate?.nexusNonFatalError("ComponentAdd collision: \(entityId) already has a component \(component)")
            assertionFailure("ComponentAdd collision: \(entityId) already has a component \(component)")
            return
        }

        // add component instances to uniform component stores
        insertComponentInstance(component, componentId, entityId)

        // assigns the component id to the entity id
        assign(componentId, entityId)

        // Update entity membership
        update(familyMembership: entityId)
    }

    func insertComponentInstance(_ component: Component, _ componentId: ComponentIdentifier, _ entityId: EntityIdentifier) {
        if componentsByType[componentId] == nil {
            componentsByType[componentId] = ManagedContiguousArray<Component>()
        }
        componentsByType[componentId]?.insert(component, at: entityId.id)
    }

    func assign(_ componentId: ComponentIdentifier, _ entityId: EntityIdentifier) {
        if componentIdsByEntity[entityId] == nil {
            componentIdsByEntity[entityId] = Set<ComponentIdentifier>(arrayLiteral: componentId)
        } else {
            componentIdsByEntity[entityId]?.insert(componentId)
        }
    }

    func assign(_ componentIds: Set<ComponentIdentifier>, _ entityId: EntityIdentifier) {
        if componentIdsByEntity[entityId] == nil {
            componentIdsByEntity[entityId] = componentIds
        } else {
            componentIdsByEntity[entityId]?.formUnion(componentIds)
        }
    }

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

        familyMembersByTraits[traits] = UnorderedSparseSet<EntityIdentifier, EntityIdentifier.Idx>()
        update(familyMembership: traits)
    }

    func update(familyMembership traits: FamilyTraitSet) {
        // FIXME: iterating all entities is costly for many entities
        var iter = entityStorage.makeIterator()
        while let entityId = iter.next() {
            update(membership: traits, for: entityId)
        }
    }

    func update(membership traits: FamilyTraitSet, for entityId: EntityIdentifier) {
        guard let componentIds = componentIdsByEntity[entityId] else {
            // no components - so skip
            return
        }

        let isMember: Bool = self.isMember(entity: entityId, inFamilyWithTraits: traits)
        if !exists(entity: entityId) && isMember {
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
