//
//  Nexus+Entity.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 13.10.17.
//

extension Nexus {
    /// Creates a new entity with a unique identifier.
    /// - Returns: The newly created entity.
    /// - Complexity: O(1)
    @discardableResult
    public func createEntity() -> Entity {
        let entityId: EntityIdentifier = entityIdGenerator.nextId()
        backend.insertEntity(entityId)
        delegate?.nexusEvent(EntityCreated(entityId: entityId))
        return Entity(nexus: self, id: entityId)
    }

    /// Creates a new entity with the provided components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The newly created entity.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func createEntity(with components: Component...) -> Entity {
        if let created = createEntityDirectly(components) {
            return created
        }
        let newEntity = createEntity()
        assign(components: components, to: newEntity.identifier)
        return newEntity
    }

    /// Creates a new entity with the provided components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The newly created entity.
    /// - Complexity: O(C + M) where C is the number of components and M is the number of families.
    @discardableResult
    public func createEntity<each C: Component>(with components: repeat each C) -> Entity {
        if delegate == nil, case let .archetype(archetype) = backend {
            var mask = ComponentMask()
            var distinct = true
            _ = (repeat Self.insertDistinct((each C).componentIndex, into: &mask, distinct: &distinct))
            if distinct, !mask.isEmpty {
                archetype.requireUnlocked()
                _ = (repeat prepareStorage((each C).self, in: archetype))
                let entityId = entityIdGenerator.nextId()
                let table = archetype.table(forExactly: mask)
                archetype.insertEntity(entityId, intoTable: table, mask: mask)
                _ = (repeat archetype.appendInitial(each components, at: (each C).componentIndex, toTable: table))
                update(familyMembership: entityId)
                return Entity(nexus: self, id: entityId)
            }
        }
        let newEntity = createEntity()
        _ = assign(components: repeat each components, entityId: newEntity.identifier)
        return newEntity
    }

    /// Creates a new entity with a collection of components.
    /// - Parameter components: The components to assign to the new entity.
    /// - Returns: The newly created entity.
    /// - Complexity: O(M) where M is the number of families.
    @discardableResult
    public func createEntity(with components: some Collection<Component>) -> Entity {
        if let created = createEntityDirectly(components) {
            return created
        }
        let entity = createEntity()
        assign(components: components, to: entity.identifier)
        return entity
    }

    private static func insertDistinct(_ componentIndex: Int, into mask: inout ComponentMask, distinct: inout Bool) {
        if mask.contains(componentIndex) {
            distinct = false
        }
        mask.insert(componentIndex)
    }

    /// Registers a component type as its first assignment would.
    private func prepareStorage<C: Component>(_: C.Type, in archetype: ArchetypeStorage) {
        let componentIndex = C.componentIndex
        if !archetype.hasStorage(for: componentIndex) {
            registerOnFirstAssignment(C.self)
        }
        archetype.register(C.self, at: componentIndex)
    }

    private func prepareStorage(of component: some Component, in archetype: ArchetypeStorage) {
        prepareStorage(type(of: component), in: archetype)
    }

    private func appendInitial(_ component: some Component, in archetype: ArchetypeStorage, toTable table: Int) {
        archetype.appendInitial(component, at: type(of: component).componentIndex, toTable: table)
    }

    /// Creates an entity directly in the archetype table of its final component set, instead of moving it from the
    /// table of one component to the next.
    ///
    /// Only without a delegate, because a delegate observes the entity gaining its components one by one, and only
    /// for distinct component types. Returns `nil` when the general path has to be taken.
    private func createEntityDirectly(_ components: some Collection<Component>) -> Entity? {
        guard delegate == nil, case let .archetype(archetype) = backend, !components.isEmpty else {
            return nil
        }
        var mask = ComponentMask()
        var distinct = true
        for component in components {
            Self.insertDistinct(type(of: component).componentIndex, into: &mask, distinct: &distinct)
        }
        guard distinct else {
            return nil
        }
        archetype.requireUnlocked()
        for component in components {
            prepareStorage(of: component, in: archetype)
        }
        let entityId = entityIdGenerator.nextId()
        let table = archetype.table(forExactly: mask)
        archetype.insertEntity(entityId, intoTable: table, mask: mask)
        for component in components {
            appendInitial(component, in: archetype, toTable: table)
        }
        update(familyMembership: entityId)
        return Entity(nexus: self, id: entityId)
    }

    /// The total number of entities managed by the Nexus.
    /// - Complexity: O(1)
    public var numEntities: Int {
        backend.entityCount
    }

    /// Creates an iterator over all entities in the nexus.
    ///
    /// Entity order is not guaranteed to stay the same over iterations.
    /// - Returns: An `EntitiesIterator`.
    /// - Complexity: O(1)
    public func makeEntitiesIterator() -> EntitiesIterator {
        EntitiesIterator(nexus: self)
    }

    /// Checks if an entity identifier refers to a living entity of the Nexus.
    ///
    /// The identifier of a destroyed entity is stale: it stays not alive, even if its slot is reused by a later entity,
    /// because the later entity has a higher generation.
    /// - Parameter entityId: The identifier of the entity to check.
    /// - Returns: `true` if the generation of the identifier matches the current generation of its slot and the slot holds an entity; otherwise, `false`.
    /// - Complexity: O(1)
    public func isAlive(_ entityId: EntityIdentifier) -> Bool {
        backend.isAlive(entityId)
    }

    /// Checks if an entity exists in the Nexus.
    /// - Parameter entityId: The identifier of the entity to check.
    /// - Returns: `true` if the entity exists; otherwise, `false`.
    /// - Complexity: O(1)
    @available(*, deprecated, renamed: "isAlive(_:)")
    public func exists(entity entityId: EntityIdentifier) -> Bool {
        isAlive(entityId)
    }

    /// Retrieves the living entity for a given identifier.
    ///
    /// - Parameter entityId: The entity identifier.
    /// - Returns: The `Entity` associated with the identifier, or `nil` if the identifier is stale or unknown.
    ///   Never a different entity that reuses the slot of a destroyed entity.
    /// - Complexity: O(1)
    public func entity(_ entityId: EntityIdentifier) -> Entity? {
        guard isAlive(entityId) else {
            return nil
        }
        return Entity(nexus: self, id: entityId)
    }

    /// Retrieves an entity instance for a given identifier, without checking that the entity is alive.
    ///
    /// Mutating a handle of a destroyed entity fails, but the handle can not be told apart from a living one before.
    /// - Parameter entityId: The entity identifier.
    /// - Returns: An `Entity` instance associated with the identifier.
    /// - Complexity: O(1)
    @available(*, deprecated, message: "Use entity(_:), which returns nil for stale or unknown identifiers.")
    public func entity(from entityId: EntityIdentifier) -> Entity {
        Entity(nexus: self, id: entityId)
    }

    /// Destroys an entity and removes it from the Nexus.
    ///
    /// - Parameter entity: The entity to destroy.
    /// - Returns: `true` if the entity was successfully destroyed; otherwise, `false`.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    @discardableResult
    public func destroy(entity: Entity) -> Bool {
        destroy(entityId: entity.identifier)
    }

    /// Destroys an entity by its identifier.
    ///
    /// This removes all components associated with the entity and releases its slot for reuse with a higher generation,
    /// so that `entityId` and all copies of it are stale afterwards.
    /// - Parameter entityId: The identifier of the entity to destroy.
    /// - Returns: `true` if the entity was found and destroyed; `false` if the identifier is stale or unknown.
    /// - Complexity: O(C * M) where C is the number of components and M is the number of families.
    @discardableResult
    public func destroy(entityId: EntityIdentifier) -> Bool {
        guard backend.isAlive(entityId) else {
            delegate?.nexusNonFatalError("EntityRemove failure: no entity \(entityId) to remove")
            return false
        }

        if removeAll(components: entityId) {
            update(familyMembership: entityId)
        }

        // Releasing a removed component can run a `deinit` that adds components again. They go with the entity,
        // so the entity must leave the families that the re-added components made it a member of.
        backend.destroyEntity(entityId)
        for family in familyList where isMember(entity: entityId, inFamilyWithTraits: family.traits) {
            remove(entityWithId: entityId, fromFamilyWithTraits: family.traits)
            delegate?.nexusEvent(FamilyMemberRemoved(member: entityId, from: family.traits))
        }

        entityIdGenerator.markUnused(entityId: entityId)

        delegate?.nexusEvent(EntityDestroyed(entityId: entityId))
        return true
    }
}

// MARK: - entities iterator

extension Nexus {
    /// An iterator over the entities managed by the Nexus, in a deterministic order.
    public struct EntitiesIterator: IteratorProtocol {
        private var iterator: AnyIterator<Entity>

        /// Creates a new iterator for the given Nexus.
        /// - Parameter nexus: The nexus to iterate over.
        @usableFromInline
        init(nexus: Nexus) {
            // The identifiers ascend by slot index, so the order is deterministic.
            var iter = nexus.backend.livingEntityIds.makeIterator()
            iterator = AnyIterator {
                guard let entityId = iter.next() else {
                    return nil
                }
                return Entity(nexus: nexus, id: entityId)
            }
        }

        /// Advances to the next entity and returns it, or `nil` if no next entity exists.
        /// - Returns: The next entity in the sequence, or `nil`.
        public func next() -> Entity? {
            iterator.next()
        }
    }
}

extension Nexus.EntitiesIterator: LazySequenceProtocol {}
extension Nexus.EntitiesIterator: Sequence {}
