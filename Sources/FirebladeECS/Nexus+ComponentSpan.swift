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
    /// - Parameters:
    ///   - type: The component type.
    ///   - body: Receives the span; its result is returned.
    /// - Complexity: O(1) plus `body`.
    @inlinable
    @discardableResult
    public func componentSpan<C: Component, Result>(reading type: C.Type, _ body: (Span<C>) throws -> Result) rethrows -> Result {
        guard case let .sparseSet(sparse) = backend else {
            return try body(Span<C>())
        }
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
    /// - Parameters:
    ///   - type: The component type.
    ///   - body: Receives the span; its result is returned.
    /// - Complexity: O(1) plus `body`.
    @inlinable
    @discardableResult
    public func componentSpan<C: Component, Result>(writing type: C.Type, _ body: (inout MutableSpan<C>) throws -> Result) rethrows -> Result {
        guard case let .sparseSet(sparse) = backend else {
            var empty = MutableSpan<C>()
            return try body(&empty)
        }
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
}
