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
    ///
    /// If `body` throws, the error propagates after the event: the component may have been changed already.
    /// - Returns: `false` if the handle is stale or the entity has no such component.
    @usableFromInline
    @discardableResult
    final func modify<C: Component>(_ type: C.Type, for entityId: EntityIdentifier, _ body: (inout C) throws -> Void) rethrows -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        var ran = false
        defer {
            // after the write access ended, so a delegate may read the component
            if ran {
                emitModified(type, for: entityId)
            }
        }
        return try backend.modify(type, for: entityId) {
            ran = true
            try body(&$0)
        }
    }

    /// Changes the component of an entity in place, adding `default` first if the entity has none.
    ///
    /// A missing component emits ``ComponentAdded``, then ``ComponentModified``. The default is evaluated only
    /// when the component is missing.
    /// - Returns: `false` if the handle is stale; nothing is inserted then.
    @usableFromInline
    @discardableResult
    final func modify<C: Component>(_ type: C.Type, default makeDefault: @autoclosure () -> C, for entityId: EntityIdentifier, _ body: (inout C) throws -> Void) rethrows -> Bool {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return false
        }
        if !backend.has(componentIndex: C.componentIndex, for: entityId) {
            guard insert(makeDefault(), entityId) else {
                return false
            }
            update(familyMembership: entityId)
            // a delegate notified about the addition may have destroyed the entity
            guard isAlive(entityId) else {
                return false
            }
        }
        return try modify(type, for: entityId, body)
    }

    // MARK: Accessor support

    /// Starts an in-place write access for a `_modify` accessor.
    ///
    /// Finish it with ``endModify(_:for:)`` or ``endModifyDiscarding(_:for:)``.
    /// - Returns: The address of the component, or `nil` if the handle is stale or the entity has no such component.
    @usableFromInline
    final func beginModify<C: Component>(_ type: C.Type, for entityId: EntityIdentifier) -> UnsafeMutablePointer<C>? {
        guard isAlive(entityId) else {
            reportStaleHandle(entityId)
            return nil
        }
        return backend.beginAccess(type, for: entityId)
    }

    /// Ends the access started by ``beginModify(_:for:)`` and emits ``ComponentModified``.
    @usableFromInline
    final func endModify<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        backend.endAccess(C.componentIndex)
        emitModified(C.self, for: entityId)
    }

    /// Ends the access started by ``beginModify(_:for:)`` for a component that was moved out and not put back:
    /// removes it, like ``Entity/remove(_:)-(ComponentIdentifier)``.
    @usableFromInline
    final func endModifyDiscarding<C: Component>(_: C.Type, for entityId: EntityIdentifier) {
        backend.endAccess(C.componentIndex)
        backend.discardMovedOut(C.self, for: entityId)
        update(familyMembership: entityId)
        delegate?.nexusEvent(ComponentRemoved(component: C.identifier, from: entityId))
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
