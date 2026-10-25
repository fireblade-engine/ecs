//
//  Nexus+ValueChanges.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

extension Nexus {
    // MARK: Value change events

    /// Delivers ``ComponentReplaced`` if the delegate subscribed to value changes.
    @usableFromInline
    final func emitReplaced<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        if deliversValueChanges {
            delegate?.nexusEvent(ComponentReplaced(component: C.identifier, entityId: entityId))
        }
    }

    /// Delivers ``ComponentModified`` if the delegate subscribed to value changes.
    @usableFromInline
    final func emitModified<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        if deliversValueChanges {
            delegate?.nexusEvent(ComponentModified(component: C.identifier, entityId: entityId))
        }
    }

    /// Delivers one ``ComponentsModified`` for a whole bulk pass if the delegate subscribed to value changes.
    @usableFromInline
    final func emitModified<C: Component>(_: C.Type, count: Int) {
        if deliversValueChanges {
            delegate?.nexusEvent(ComponentsModified(component: C.identifier, count: count))
        }
    }

    // MARK: Writes

    /// Changes the component of an entity in place and emits ``ComponentModified`` afterwards.
    /// - Returns: `false` if the handle is stale or the entity has no such component.
    @usableFromInline
    @discardableResult
    final func modify<C: Component>(_ type: C.Type, for entityId: EntityIdentifier, _ body: (inout C) -> Void) -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        guard backend.modify(type, for: entityId, body) else {
            return false
        }
        emitModified(type, for: entityId)
        return true
    }

    /// Changes the component of an entity in place, adding `default` first if the entity has none.
    ///
    /// A missing component emits ``ComponentAdded``, then ``ComponentModified``.
    /// - Returns: `false` if the handle is stale.
    @usableFromInline
    @discardableResult
    final func modify<C: Component>(_ type: C.Type, default makeDefault: @autoclosure () -> C, for entityId: EntityIdentifier, _ body: (inout C) -> Void) -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        if !backend.has(componentIndex: C.componentIndex, for: entityId) {
            guard insert(makeDefault(), entityId) else {
                return false
            }
            update(familyMembership: entityId)
        }
        return modify(type, for: entityId, body)
    }

    /// Gives `body` write access to all components of a type as contiguous buffers and emits one
    /// ``ComponentsModified`` afterwards, not one event per entity.
    @usableFromInline
    final func withComponents<C: Component>(of type: C.Type, _ body: (UnsafeBufferPointer<UInt32>, UnsafeMutableBufferPointer<C>) -> Void) {
        var count = 0
        backend.withComponents(of: type) { ids, components in
            count = components.count
            body(ids, components)
        }
        if count > 0 {
            emitModified(type, count: count)
        }
    }
}
