//
//  Nexus+ComponentSpan.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

// `Span` and `MutableSpan` need the 26 releases of the Apple platforms (the Swift 6.2 standard library); the rest of the
// package keeps its minimum deployment targets, so every API that hands out a span is gated.

@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
extension Nexus {
    /// Gives `body` read access to all components of a type as one contiguous `Span`.
    ///
    /// The span covers every component of the type in storage order, which is not the creation order once components were
    /// removed. It is zero copy: it views the storage itself. Because `Span` is `~Escapable`, it cannot leave `body`
    /// (storing it in a variable outside the closure or returning it is a compile time error), so it can never dangle.
    ///
    /// ```swift
    /// var maxX = 0
    /// nexus.componentSpan(reading: Position.self) { (positions: Span<Position>) in
    ///     for i in positions.indices { maxX = max(maxX, positions[i].x) }
    /// }
    /// ```
    ///
    /// `Span` is not a `Sequence`: loop over `indices`. Element access is bounds checked.
    ///
    /// While `body` runs the type is locked for reading: structural changes (creating or destroying entities, adding or
    /// removing components, replacing a component with `set`) and writes to the type stop the process with a message,
    /// since they would move or change what the span views. Reading the component through the nexus and reading
    /// the type again are fine. Collect changes and apply them after the call.
    ///
    /// An empty storage (or a type no entity ever had) passes an empty span.
    ///
    /// ### Storage
    ///
    /// The sparse-set storage keeps all components of a type in one array, so the span always views the storage itself.
    /// The archetype storage keeps one column per table (one table per component set), so entities with different
    /// component sets are not next to each other. If one table holds all components of the type the span views its column,
    /// as above. If several tables hold them, the span views a temporary copy that is made table by table, which costs
    /// one allocation and O(N) copying per call and is released after `body`. Use
    /// ``Family/forEachComponentSpan(reading:_:)`` to get zero copy spans, one batch per table.
    ///
    /// - Parameters:
    ///   - type: The component type.
    ///   - body: Receives the span; its result is returned.
    /// - Complexity: O(1) plus `body`.
    @inlinable
    @discardableResult
    public func componentSpan<C: Component, Result>(reading type: C.Type, _ body: (Span<C>) throws -> Result) rethrows -> Result {
        switch backend {
        case let .sparseSet(sparse):
            try componentSpan(in: sparse, reading: type, body)

        case let .archetype(archetype):
            try componentSpan(in: archetype, reading: type, body)
        }
    }

    @inlinable
    func componentSpan<C: Component, Result>(in sparse: SparseSetStorage, reading _: C.Type, _ body: (Span<C>) throws -> Result) rethrows -> Result {
        let componentIndex = C.componentIndex
        guard let storage = sparse.existing(C.self, at: componentIndex), !storage.isEmpty else {
            sparse.requireReadable(componentIndex)
            return try body(Span<C>())
        }
        let wasReading = sparse.beginRead(componentIndex)
        sparse.lockDepth += 1
        defer {
            sparse.lockDepth -= 1
            sparse.endRead(componentIndex, wasReading: wasReading)
        }
        let span = Span<C>(_unsafeElements: UnsafeBufferPointer(start: storage.base, count: storage.count))
        return try body(span)
    }

    @inlinable
    func componentSpan<C: Component, Result>(in archetype: ArchetypeStorage, reading _: C.Type, _ body: (Span<C>) throws -> Result) rethrows -> Result {
        let componentIndex = C.componentIndex
        let rows = archetype.rowCount(of: componentIndex)
        guard rows.total > 0 else {
            archetype.requireReadable(componentIndex)
            return try body(Span<C>())
        }
        let wasReading = archetype.beginRead(componentIndex)
        archetype.lockDepth += 1
        defer {
            archetype.lockDepth -= 1
            archetype.endRead(componentIndex, wasReading: wasReading)
        }
        if let table = rows.onlyTable {
            // one table holds all components: view its column
            let span = Span<C>(_unsafeElements: UnsafeBufferPointer(start: table.base(C.self, at: componentIndex), count: rows.total))
            return try body(span)
        }
        // the components are spread over several tables: view a copy
        let copy = UnsafeMutableBufferPointer<C>.allocate(capacity: rows.total)
        archetype.gather(C.self, at: componentIndex, into: copy.baseAddress.unsafelyUnwrapped)
        defer {
            copy.baseAddress.unsafelyUnwrapped.deinitialize(count: rows.total)
            copy.deallocate()
        }
        return try body(Span<C>(_unsafeElements: UnsafeBufferPointer(copy)))
    }

    /// Gives `body` write access to all components of a type as one contiguous `MutableSpan`.
    ///
    /// Writes through the span land in the storage. Like with ``componentSpan(reading:_:)`` the span is zero copy and
    /// cannot escape `body`.
    ///
    /// ```swift
    /// nexus.componentSpan(writing: Velocity.self) { (velocities: inout MutableSpan<Velocity>) in
    ///     for i in velocities.indices { velocities[i].dx *= 0.98 }
    /// }
    /// ```
    ///
    /// While `body` runs the type is locked for writing, and the nexus like in ``Entity/modify(_:_:)``: structural
    /// changes, reading or writing the same type again (through the nexus, an entity or another span) stop the process
    /// with a message instead of leaving a dangling or aliased write. Other component types can be read.
    ///
    /// A delegate subscribed to ``NexusEventMask/valueChanges`` receives one ``ComponentsModified`` after `body` returned
    /// (also when it threw), not one event per component. An empty storage passes an empty span and emits nothing.
    ///
    /// ### Storage
    ///
    /// With the archetype storage, a type that lives in several tables (entities with different component sets) is written
    /// through a temporary copy, as ``componentSpan(reading:_:)`` describes: the writes reach the components when `body`
    /// returns, also if it throws. Nothing can observe the difference meanwhile, because the type is locked for writing.
    ///
    /// - Parameters:
    ///   - type: The component type.
    ///   - body: Receives the span; its result is returned.
    /// - Complexity: O(1) plus `body`.
    @inlinable
    @discardableResult
    public func componentSpan<C: Component, Result>(writing type: C.Type, _ body: (inout MutableSpan<C>) throws -> Result) rethrows -> Result {
        switch backend {
        case let .sparseSet(sparse):
            try componentSpan(in: sparse, writing: type, body)

        case let .archetype(archetype):
            try componentSpan(in: archetype, writing: type, body)
        }
    }

    @inlinable
    func componentSpan<C: Component, Result>(in sparse: SparseSetStorage, writing _: C.Type, _ body: (inout MutableSpan<C>) throws -> Result) rethrows -> Result {
        let componentIndex = C.componentIndex
        guard let storage = sparse.existing(C.self, at: componentIndex), !storage.isEmpty else {
            sparse.beginWrite(componentIndex)
            sparse.endWrite(componentIndex)
            var empty = MutableSpan<C>()
            return try body(&empty)
        }
        let count = storage.count
        sparse.beginWrite(componentIndex)
        sparse.lockDepth += 1
        defer {
            sparse.lockDepth -= 1
            sparse.endWrite(componentIndex)
            // after the write access ended, so a delegate may read the components
            emitModified(C.self, count: count)
        }
        var span = MutableSpan<C>(_unsafeElements: UnsafeMutableBufferPointer(start: storage.base, count: count))
        return try body(&span)
    }

    @inlinable
    func componentSpan<C: Component, Result>(in archetype: ArchetypeStorage, writing _: C.Type, _ body: (inout MutableSpan<C>) throws -> Result) rethrows -> Result {
        let componentIndex = C.componentIndex
        let rows = archetype.rowCount(of: componentIndex)
        guard rows.total > 0 else {
            archetype.beginWrite(componentIndex)
            archetype.endWrite(componentIndex)
            var empty = MutableSpan<C>()
            return try body(&empty)
        }
        archetype.beginWrite(componentIndex)
        archetype.lockDepth += 1
        defer {
            archetype.lockDepth -= 1
            archetype.endWrite(componentIndex)
            // after the write access ended, so a delegate may read the components
            emitModified(C.self, count: rows.total)
        }
        if let table = rows.onlyTable {
            // one table holds all components: write through to its column
            var span = MutableSpan<C>(_unsafeElements: UnsafeMutableBufferPointer(start: table.base(C.self, at: componentIndex), count: rows.total))
            return try body(&span)
        }
        // the components are spread over several tables: write to a copy and store it back, also if `body` throws
        let copy = UnsafeMutableBufferPointer<C>.allocate(capacity: rows.total)
        archetype.gather(C.self, at: componentIndex, into: copy.baseAddress.unsafelyUnwrapped)
        defer {
            archetype.scatter(C.self, at: componentIndex, from: copy.baseAddress.unsafelyUnwrapped)
            copy.baseAddress.unsafelyUnwrapped.deinitialize(count: rows.total)
            copy.deallocate()
        }
        var span = MutableSpan<C>(_unsafeElements: copy)
        return try body(&span)
    }
}
