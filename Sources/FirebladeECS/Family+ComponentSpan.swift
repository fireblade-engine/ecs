//
//  Family+ComponentSpan.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

// swiftlint:disable file_length function_body_length line_length

@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)
extension Family {
    /// Iterates the members of this family in batches, reading 0 and writing 1 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<W1: Component>(
        writing wType1: W1.Type,
        _ body: (inout MutableSpan<W1>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(W1.self)
        let members = memberIds
        guard !members.isEmpty, let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard ws1.slot(of: next) == wSlot1 + length else { break }
                    length += 1
                }
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                visited += length
                try body(&wSpan1)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 0 and writing 2 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<W1: Component, W2: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (inout MutableSpan<W1>, inout MutableSpan<W2>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(W1.self)
        requireRequired(W2.self)
        let members = memberIds
        guard !members.isEmpty, let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        sparse.beginWrite(W2.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.endWrite(W2.componentIndex)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
                nexus.emitModified(W2.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                let wSlot2 = ws2.slot(of: key)
                precondition(wSlot2 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard ws1.slot(of: next) == wSlot1 + length, ws2.slot(of: next) == wSlot2 + length else { break }
                    length += 1
                }
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                var wSpan2 = MutableSpan<W2>(_unsafeElements: UnsafeMutableBufferPointer(start: ws2.base + wSlot2, count: length))
                visited += length
                try body(&wSpan1, &wSpan2)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 1 and writing 0 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<R1: Component>(
        reading rType1: R1.Type,
        _ body: (Span<R1>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex) else { return }
        sparse.lockDepth += 1
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        var visited = 0
        defer {
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.lockDepth -= 1
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                visited += length
                try body(rSpan1)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, giving `body` the components of a batch as contiguous spans.
    ///
    /// Reads 1 and writes 1 component type: `body` receives a `Span` of the read type and an `inout` `MutableSpan`
    /// of the written type. Within one call all spans have the same count and the same order: element `i` of every
    /// span belongs to the same member. The batches visit every member exactly once, in the iteration order of the
    /// family.
    ///
    /// ```swift
    /// movers.forEachComponentSpan(reading: Velocity.self, writing: Position.self) { velocities, positions in
    ///     for i in positions.indices { positions[i].x += velocities[i].dx }
    /// }
    /// ```
    ///
    /// ### Batches
    ///
    /// The sparse-set storage keeps every component type in its own dense array, so the components of the members of a
    /// family are not necessarily next to each other in all arrays. The spans view the storage itself and nothing is
    /// copied or allocated, so a batch is a maximal run of members whose components are consecutive in every involved
    /// array. Entities that were created together and never had components removed form one big batch; after
    /// churn (removing components swap-removes) the batches get shorter, down to 1 element per call in the worst case.
    /// Write `body` so that it is correct for any batch size, and do not rely on the number of calls. Storages that
    /// keep the columns of a family aligned (archetype tables, owning groups) will always pass one batch per table.
    ///
    /// ### Rules
    ///
    /// Every type must be a required component of the family. The spans cannot escape `body` (`Span` is `~Escapable`).
    /// While the pass runs the nexus is locked like in ``forEach(reading:writing:_:)``: structural changes, reading a
    /// written type through the nexus, writing a type twice, and writing a type that is read (or reading a written
    /// type) stop the process with a message.
    ///
    /// A delegate subscribed to ``NexusEventMask/valueChanges`` receives one ``ComponentsModified`` per written type
    /// and call, not one event per batch.
    ///
    /// - Complexity: O(N) where N is the number of members, plus one hash lookup per component type.
    @inlinable
    public func forEachComponentSpan<R1: Component, W1: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ body: (Span<R1>, inout MutableSpan<W1>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        requireRequired(W1.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length, ws1.slot(of: next) == wSlot1 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                visited += length
                try body(rSpan1, &wSpan1)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 1 and writing 2 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<R1: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (Span<R1>, inout MutableSpan<W1>, inout MutableSpan<W2>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        sparse.beginWrite(W2.componentIndex)
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.endWrite(W2.componentIndex)
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
                nexus.emitModified(W2.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                let wSlot2 = ws2.slot(of: key)
                precondition(wSlot2 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length, ws1.slot(of: next) == wSlot1 + length, ws2.slot(of: next) == wSlot2 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                var wSpan2 = MutableSpan<W2>(_unsafeElements: UnsafeMutableBufferPointer(start: ws2.base + wSlot2, count: length))
                visited += length
                try body(rSpan1, &wSpan1, &wSpan2)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 2 and writing 0 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<R1: Component, R2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ body: (Span<R1>, Span<R2>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        requireRequired(R2.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex) else { return }
        sparse.lockDepth += 1
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        let wasReading2 = sparse.beginRead(R2.componentIndex)
        var visited = 0
        defer {
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.endRead(R2.componentIndex, wasReading: wasReading2)
            sparse.lockDepth -= 1
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                let rSlot2 = rs2.slot(of: key)
                precondition(rSlot2 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length, rs2.slot(of: next) == rSlot2 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                let rSpan2 = Span<R2>(_unsafeElements: UnsafeBufferPointer(start: rs2.base + rSlot2, count: length))
                visited += length
                try body(rSpan1, rSpan2)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 2 and writing 1 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<R1: Component, R2: Component, W1: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ body: (Span<R1>, Span<R2>, inout MutableSpan<W1>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        let wasReading2 = sparse.beginRead(R2.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.endRead(R2.componentIndex, wasReading: wasReading2)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                let rSlot2 = rs2.slot(of: key)
                precondition(rSlot2 >= 0, "member without a required component")
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length, rs2.slot(of: next) == rSlot2 + length, ws1.slot(of: next) == wSlot1 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                let rSpan2 = Span<R2>(_unsafeElements: UnsafeBufferPointer(start: rs2.base + rSlot2, count: length))
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                visited += length
                try body(rSpan1, rSpan2, &wSpan1)
                start += length
            }
        }
    }

    /// Iterates the members of this family in batches, reading 2 and writing 2 component types as contiguous spans.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEachComponentSpan<R1: Component, R2: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (Span<R1>, Span<R2>, inout MutableSpan<W1>, inout MutableSpan<W2>) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        let members = memberIds
        guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
        sparse.lockDepth += 1
        sparse.beginWrite(W1.componentIndex)
        sparse.beginWrite(W2.componentIndex)
        let wasReading1 = sparse.beginRead(R1.componentIndex)
        let wasReading2 = sparse.beginRead(R2.componentIndex)
        var visited = 0
        defer {
            sparse.endWrite(W1.componentIndex)
            sparse.endWrite(W2.componentIndex)
            sparse.endRead(R1.componentIndex, wasReading: wasReading1)
            sparse.endRead(R2.componentIndex, wasReading: wasReading2)
            sparse.lockDepth -= 1
            if visited > 0 {
                nexus.emitModified(W1.self, count: visited)
                nexus.emitModified(W2.self, count: visited)
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            let total = entries.count
            var start = 0
            while start < total {
                let key = entries[start].key
                let rSlot1 = rs1.slot(of: key)
                precondition(rSlot1 >= 0, "member without a required component")
                let rSlot2 = rs2.slot(of: key)
                precondition(rSlot2 >= 0, "member without a required component")
                let wSlot1 = ws1.slot(of: key)
                precondition(wSlot1 >= 0, "member without a required component")
                let wSlot2 = ws2.slot(of: key)
                precondition(wSlot2 >= 0, "member without a required component")
                var length = 1
                while start + length < total {
                    let next = entries[start + length].key
                    guard rs1.slot(of: next) == rSlot1 + length, rs2.slot(of: next) == rSlot2 + length, ws1.slot(of: next) == wSlot1 + length, ws2.slot(of: next) == wSlot2 + length else { break }
                    length += 1
                }
                let rSpan1 = Span<R1>(_unsafeElements: UnsafeBufferPointer(start: rs1.base + rSlot1, count: length))
                let rSpan2 = Span<R2>(_unsafeElements: UnsafeBufferPointer(start: rs2.base + rSlot2, count: length))
                var wSpan1 = MutableSpan<W1>(_unsafeElements: UnsafeMutableBufferPointer(start: ws1.base + wSlot1, count: length))
                var wSpan2 = MutableSpan<W2>(_unsafeElements: UnsafeMutableBufferPointer(start: ws2.base + wSlot2, count: length))
                visited += length
                try body(rSpan1, rSpan2, &wSpan1, &wSpan2)
                start += length
            }
        }
    }
}
