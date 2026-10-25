//
//  ArchetypeStorage+Component.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus.ArchetypeStorage {
    // MARK: Typed component access

    /// Adds a component to a living entity, or replaces the one it has.
    @inlinable
    func set<C: Component>(_ component: C, at componentIndex: Int, for entityId: EntityIdentifier) {
        requireUnlocked()
        precondition(entities.isAlive(entityId), "set on a dead entity")
        let location = locations[Int(entityId.index)]
        if let column = column(C.self, at: componentIndex, in: location) {
            column[Int(location.row)] = component
        } else {
            add(component, at: componentIndex, for: entityId, from: location)
        }
    }

    @usableFromInline
    func add<C: Component>(_ component: C, at componentIndex: Int, for entityId: EntityIdentifier, from location: Nexus.EntityLocation) {
        register(C.self, at: componentIndex)
        let target = tableAfterAdding(C.self, at: componentIndex, to: Int(location.table))
        _ = move(entityId.index, to: target)
        tables[target].column(C.self, at: componentIndex).unsafelyUnwrapped.append(component)
        entities.insert(componentIndex, into: entityId)
    }

    @inlinable
    func get<C: Component>(_: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C? {
        requireReadable(componentIndex)
        guard entities.isAlive(entityId) else {
            return nil
        }
        let location = locations[Int(entityId.index)]
        return column(C.self, at: componentIndex, in: location)?[Int(location.row)]
    }

    /// The component of a living entity that must have it.
    ///
    /// Checks the generation of the identifier and that the entity has the component: a stale identifier or a
    /// missing component traps with a message instead of reading another entity's component.
    @inlinable
    func unsafeGet<C: Component>(_: C.Type, at componentIndex: Int, for entityId: EntityIdentifier) -> C {
        requireReadable(componentIndex)
        guard entities.isAlive(entityId) else {
            preconditionFailure("entity \(entityId) is not alive or has no component \(C.self)")
        }
        let location = locations[Int(entityId.index)]
        guard let column = column(C.self, at: componentIndex, in: location) else {
            preconditionFailure("entity \(entityId) has no component \(C.self)")
        }
        return column[Int(location.row)]
    }

    /// Whether a column for the type exists in some table: the type was added to an entity before.
    @inlinable
    func hasStorage(for componentIndex: Int) -> Bool {
        componentIndex >= 0 && componentIndex < prototypes.count && prototypes[componentIndex] != nil
    }

    @inlinable
    func has(componentIndex: Int, for entityId: EntityIdentifier) -> Bool {
        entities.mask(of: entityId)?.contains(componentIndex) ?? false
    }

    // MARK: Untyped slow paths

    /// The indices of the component types of a living entity, ascending.
    @usableFromInline
    func componentIndices(of entityId: EntityIdentifier) -> [Int] {
        var result: [Int] = []
        entities.mask(of: entityId)?.forEachIndex { result.append($0) }
        return result
    }

    /// The number of components of a living entity.
    @usableFromInline
    func componentCount(of entityId: EntityIdentifier) -> Int {
        entities.mask(of: entityId)?.count ?? 0
    }

    /// The number of component instances in all tables.
    @usableFromInline var totalComponentCount: Int {
        tables.reduce(0) { $0 + $1.rowCount * $1.columnIndices.count }
    }

    @usableFromInline
    func identifier(ofComponentIndex componentIndex: Int) -> ComponentIdentifier? {
        componentIndex >= 0 && componentIndex < prototypes.count ? prototypes[componentIndex]?.identifier : nil
    }

    @usableFromInline
    @discardableResult
    func remove(componentIndex: Int, from entityId: EntityIdentifier) -> Bool {
        requireUnlocked()
        guard entities.mask(of: entityId)?.contains(componentIndex) == true else {
            return false
        }
        let target = tableAfterRemoving(componentIndex, from: Int(locations[Int(entityId.index)].table))
        let dropped = move(entityId.index, to: target)
        entities.remove(componentIndex, from: entityId)
        // released last: a `deinit` that re-enters sees the component gone from table and entity
        withExtendedLifetime(dropped) {}
        return true
    }

    @usableFromInline
    func anyComponent(componentIndex: Int, for entityId: EntityIdentifier) -> (any Component)? {
        requireReadable(componentIndex)
        guard entities.mask(of: entityId)?.contains(componentIndex) == true else {
            return nil
        }
        let location = locations[Int(entityId.index)]
        return tables[Int(location.table)].columns[componentIndex]?.anyValue(at: Int(location.row))
    }
}
