// swiftlint:disable all
// swiftformat:disable all
//
// GENERATED FILE, DO NOT EDIT.
// Regenerate with Scripts/generate-read-write-api.sh and commit the result.
//

extension Family {
    /// Iterates the members of this family, reading 0 component types and changing 1 component type in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<W1: Component>(
        writing wType1: W1.Type,
        _ body: (inout W1) throws -> Void
    ) rethrows {
        requireRequired(W1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
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
            let wBase1 = ws1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(&wBase1[wSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(&wBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 0 component types and changing 2 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<W1: Component, W2: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (inout W1, inout W2) throws -> Void
    ) rethrows {
        requireRequired(W1.self)
        requireRequired(W2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
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
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(&wBase1[wSlot1], &wBase2[wSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(&wBase1[row], &wBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 0 component types and changing 3 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<W1: Component, W2: Component, W3: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (inout W1, inout W2, inout W3) throws -> Void
    ) rethrows {
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(&wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(&wBase1[row], &wBase2[row], &wBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 0 component types and changing 4 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<W1: Component, W2: Component, W3: Component, W4: Component>(
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows {
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        requireRequired(W4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex), let ws4 = sparse.existing(W4.self, at: W4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.beginWrite(W4.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.endWrite(W4.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let wBase4 = ws4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    let wSlot4 = ws4.slot(of: key)
                    precondition(wSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(&wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3], &wBase4[wSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.beginWrite(W4.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.endWrite(W4.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    let wBase4 = table.base(W4.self, at: W4.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(&wBase1[row], &wBase2[row], &wBase3[row], &wBase4[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 1 component type and changing 0 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component>(
        reading rType1: R1.Type,
        _ body: (R1) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                sparse.lockDepth -= 1
            }
            let rBase1 = rs1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.requireReadable(R1.componentIndex)
            defer {
                archetype.lockDepth -= 1
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    for row in 0 ..< count {
                        try body(rBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading some of their components and changing others in place.
    ///
    /// `body` receives the read components first (as copies), then the written ones as `inout`. The writes land
    /// in the component storage directly. Overloads exist for 0 to 4 read and 0 to 4 written component types, and a
    /// parameter pack overload covers more. Every fixed arity overload resolves the typed storages once and then runs
    /// a plain loop over the members: no allocation and no dynamic dispatch per member.
    ///
    /// ```swift
    /// let movers = nexus.family(requiresAll: Position.self, Velocity.self)
    /// movers.forEach(reading: Velocity.self, writing: Position.self) { velocity, position in
    ///     position.x += velocity.dx
    /// }
    /// ```
    ///
    /// Access is declared like the `in` and `inout` term modifiers of flecs queries
    /// ("Access modifiers" in <https://github.com/SanderMertens/flecs/blob/master/docs/Queries.md>), whose `each` callbacks take `const T&`
    /// for reads and `T&` for writes: here the labels `reading:` and `writing:` state it.
    ///
    /// - Every read and written type must be a required component of this family, not an excluded one.
    /// - The written types must be pairwise different and different from the read types, and a pass must not nest
    ///   a write access to a type that an enclosing pass or `modify` writes. Violations trap.
    /// - While `body` runs, structural changes trap: creating or destroying entities, adding or removing
    ///   components, and replacing a component with `set`. Collect them and apply them after the pass, and write
    ///   changed values through the `inout` parameters. Reading a written type through the nexus
    ///   (for example `entity.get(_:)`) traps, too.
    /// - Members are visited once each. The sparse-set storage visits them in the order of the family's member list, the
    ///   archetype storage table by table and row by row; neither order is a contract, and structural changes reorder them.
    /// - If the delegate subscribed to ``NexusEventMask/valueChanges``, one ``ComponentsModified`` event per written type
    ///   is delivered after the pass, not one per member. If `body` throws, the pass ends there, members already visited,
    ///   including the one that threw, stay changed and the events cover them.
    ///
    /// - Parameters:
    ///   - rType1: The component type to read.
    ///   - wType1: The component type to change in place.
    ///   - body: Called once per member.
    /// - Complexity: O(N) where N is the number of members, plus one hash lookup per component type.
    @inlinable
    public func forEach<R1: Component, W1: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ body: (R1, inout W1) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(W1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let wBase1 = ws1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], &wBase1[wSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], &wBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 1 component type and changing 2 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, inout W1, inout W2) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.requireReadable(R1.componentIndex)
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
            let rBase1 = rs1.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], &wBase1[wSlot1], &wBase2[wSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], &wBase1[row], &wBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 1 component type and changing 3 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, W1: Component, W2: Component, W3: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], &wBase1[row], &wBase2[row], &wBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 1 component type and changing 4 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        reading rType1: R1.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        requireRequired(W4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex), let ws4 = sparse.existing(W4.self, at: W4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.beginWrite(W4.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.endWrite(W4.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let wBase4 = ws4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    let wSlot4 = ws4.slot(of: key)
                    precondition(wSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3], &wBase4[wSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.beginWrite(W4.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.endWrite(W4.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    let wBase4 = table.base(W4.self, at: W4.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], &wBase1[row], &wBase2[row], &wBase3[row], &wBase4[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 2 component types and changing 0 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ body: (R1, R2) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                sparse.lockDepth -= 1
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            defer {
                archetype.lockDepth -= 1
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    for row in 0 ..< count {
                        try body(rBase1[row], rBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 2 component types and changing 1 component type in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, W1: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, inout W1) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let wBase1 = ws1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], &wBase1[wSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], &wBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 2 component types and changing 2 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, inout W1, inout W2) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
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
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], &wBase1[wSlot1], &wBase2[wSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], &wBase1[row], &wBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 2 component types and changing 3 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, W1: Component, W2: Component, W3: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], &wBase1[row], &wBase2[row], &wBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 2 component types and changing 4 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        requireRequired(W4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex), let ws4 = sparse.existing(W4.self, at: W4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.beginWrite(W4.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.endWrite(W4.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let wBase4 = ws4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    let wSlot4 = ws4.slot(of: key)
                    precondition(wSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3], &wBase4[wSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.beginWrite(W4.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.endWrite(W4.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    let wBase4 = table.base(W4.self, at: W4.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], &wBase1[row], &wBase2[row], &wBase3[row], &wBase4[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 3 component types and changing 0 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ body: (R1, R2, R3) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                sparse.lockDepth -= 1
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            defer {
                archetype.lockDepth -= 1
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    for row in 0 ..< count {
                        try body(rBase1[row], rBase2[row], rBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 3 component types and changing 1 component type in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, W1: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, R3, inout W1) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(W1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let wBase1 = ws1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], &wBase1[wSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], &wBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 3 component types and changing 2 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, R3, inout W1, inout W2) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
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
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], &wBase1[wSlot1], &wBase2[wSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], &wBase1[row], &wBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 3 component types and changing 3 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component, W3: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, R3, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], &wBase1[row], &wBase2[row], &wBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 3 component types and changing 4 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, R3, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        requireRequired(W4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex), let ws4 = sparse.existing(W4.self, at: W4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.beginWrite(W4.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.endWrite(W4.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let wBase4 = ws4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    let wSlot4 = ws4.slot(of: key)
                    precondition(wSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3], &wBase4[wSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.beginWrite(W4.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.endWrite(W4.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    let wBase4 = table.base(W4.self, at: W4.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], &wBase1[row], &wBase2[row], &wBase3[row], &wBase4[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 4 component types and changing 0 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, R4: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        _ body: (R1, R2, R3, R4) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(R4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let rs4 = sparse.existing(R4.self, at: R4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            sparse.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                sparse.lockDepth -= 1
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let rBase4 = rs4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let rSlot4 = rs4.slot(of: key)
                    precondition(rSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], rBase4[rSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            archetype.requireReadable(R4.componentIndex)
            defer {
                archetype.lockDepth -= 1
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let rBase4 = table.base(R4.self, at: R4.componentIndex)
                    for row in 0 ..< count {
                        try body(rBase1[row], rBase2[row], rBase3[row], rBase4[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 4 component types and changing 1 component type in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ body: (R1, R2, R3, R4, inout W1) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(R4.self)
        requireRequired(W1.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let rs4 = sparse.existing(R4.self, at: R4.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            sparse.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let rBase4 = rs4.base
            let wBase1 = ws1.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let rSlot4 = rs4.slot(of: key)
                    precondition(rSlot4 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], rBase4[rSlot4], &wBase1[wSlot1])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            archetype.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let rBase4 = table.base(R4.self, at: R4.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], rBase4[row], &wBase1[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 4 component types and changing 2 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(R4.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let rs4 = sparse.existing(R4.self, at: R4.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            sparse.requireReadable(R4.componentIndex)
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
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let rBase4 = rs4.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let rSlot4 = rs4.slot(of: key)
                    precondition(rSlot4 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], rBase4[rSlot4], &wBase1[wSlot1], &wBase2[wSlot2])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            archetype.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let rBase4 = table.base(R4.self, at: R4.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], rBase4[row], &wBase1[row], &wBase2[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 4 component types and changing 3 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component, W3: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2, inout W3) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(R4.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let rs4 = sparse.existing(R4.self, at: R4.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            sparse.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let rBase4 = rs4.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let rSlot4 = rs4.slot(of: key)
                    precondition(rSlot4 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], rBase4[rSlot4], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            archetype.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let rBase4 = table.base(R4.self, at: R4.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], rBase4[row], &wBase1[row], &wBase2[row], &wBase3[row])
                    }
                }
            }
        }
    }

    /// Iterates the members of this family, reading 4 component types and changing 4 component types in place.
    ///
    /// Same contract as the overload that reads 1 and writes 1 component type, see there.
    @inlinable
    public func forEach<R1: Component, R2: Component, R3: Component, R4: Component, W1: Component, W2: Component, W3: Component, W4: Component>(
        reading rType1: R1.Type,
        _ rType2: R2.Type,
        _ rType3: R3.Type,
        _ rType4: R4.Type,
        writing wType1: W1.Type,
        _ wType2: W2.Type,
        _ wType3: W3.Type,
        _ wType4: W4.Type,
        _ body: (R1, R2, R3, R4, inout W1, inout W2, inout W3, inout W4) throws -> Void
    ) rethrows {
        requireRequired(R1.self)
        requireRequired(R2.self)
        requireRequired(R3.self)
        requireRequired(R4.self)
        requireRequired(W1.self)
        requireRequired(W2.self)
        requireRequired(W3.self)
        requireRequired(W4.self)
        switch nexus.backend {
        case let .sparseSet(sparse):
            let members = memberIds
            guard !members.isEmpty, let rs1 = sparse.existing(R1.self, at: R1.componentIndex), let rs2 = sparse.existing(R2.self, at: R2.componentIndex), let rs3 = sparse.existing(R3.self, at: R3.componentIndex), let rs4 = sparse.existing(R4.self, at: R4.componentIndex), let ws1 = sparse.existing(W1.self, at: W1.componentIndex), let ws2 = sparse.existing(W2.self, at: W2.componentIndex), let ws3 = sparse.existing(W3.self, at: W3.componentIndex), let ws4 = sparse.existing(W4.self, at: W4.componentIndex) else { return }
            sparse.lockDepth += 1
            sparse.beginWrite(W1.componentIndex)
            sparse.beginWrite(W2.componentIndex)
            sparse.beginWrite(W3.componentIndex)
            sparse.beginWrite(W4.componentIndex)
            sparse.requireReadable(R1.componentIndex)
            sparse.requireReadable(R2.componentIndex)
            sparse.requireReadable(R3.componentIndex)
            sparse.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                sparse.endWrite(W1.componentIndex)
                sparse.endWrite(W2.componentIndex)
                sparse.endWrite(W3.componentIndex)
                sparse.endWrite(W4.componentIndex)
                sparse.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            let rBase1 = rs1.base
            let rBase2 = rs2.base
            let rBase3 = rs3.base
            let rBase4 = rs4.base
            let wBase1 = ws1.base
            let wBase2 = ws2.base
            let wBase3 = ws3.base
            let wBase4 = ws4.base
            let entries = members.storage.dense
            try entries.withUnsafeBufferPointer { entries in
                for entry in entries {
                    let key = entry.key
                    let rSlot1 = rs1.slot(of: key)
                    precondition(rSlot1 >= 0, "member without a required component")
                    let rSlot2 = rs2.slot(of: key)
                    precondition(rSlot2 >= 0, "member without a required component")
                    let rSlot3 = rs3.slot(of: key)
                    precondition(rSlot3 >= 0, "member without a required component")
                    let rSlot4 = rs4.slot(of: key)
                    precondition(rSlot4 >= 0, "member without a required component")
                    let wSlot1 = ws1.slot(of: key)
                    precondition(wSlot1 >= 0, "member without a required component")
                    let wSlot2 = ws2.slot(of: key)
                    precondition(wSlot2 >= 0, "member without a required component")
                    let wSlot3 = ws3.slot(of: key)
                    precondition(wSlot3 >= 0, "member without a required component")
                    let wSlot4 = ws4.slot(of: key)
                    precondition(wSlot4 >= 0, "member without a required component")
                    visited += 1
                    try body(rBase1[rSlot1], rBase2[rSlot2], rBase3[rSlot3], rBase4[rSlot4], &wBase1[wSlot1], &wBase2[wSlot2], &wBase3[wSlot3], &wBase4[wSlot4])
                }
            }
        case let .archetype(archetype):
            guard !memberIds.isEmpty, let filter = nexus.familyFiltersByTraits[traits] else { return }
            let query = archetype.matchingTables(filter)
            archetype.lockDepth += 1
            archetype.beginWrite(W1.componentIndex)
            archetype.beginWrite(W2.componentIndex)
            archetype.beginWrite(W3.componentIndex)
            archetype.beginWrite(W4.componentIndex)
            archetype.requireReadable(R1.componentIndex)
            archetype.requireReadable(R2.componentIndex)
            archetype.requireReadable(R3.componentIndex)
            archetype.requireReadable(R4.componentIndex)
            var visited = 0
            defer {
                archetype.endWrite(W1.componentIndex)
                archetype.endWrite(W2.componentIndex)
                archetype.endWrite(W3.componentIndex)
                archetype.endWrite(W4.componentIndex)
                archetype.lockDepth -= 1
                if visited > 0 {
                    nexus.emitModified(W1.self, count: visited)
                    nexus.emitModified(W2.self, count: visited)
                    nexus.emitModified(W3.self, count: visited)
                    nexus.emitModified(W4.self, count: visited)
                }
            }
            for entry in query.tables {
                try entry._withUnsafeGuaranteedRef { table in
                    let count = table.entities.count
                    guard count > 0 else { return }
                    let rBase1 = table.base(R1.self, at: R1.componentIndex)
                    let rBase2 = table.base(R2.self, at: R2.componentIndex)
                    let rBase3 = table.base(R3.self, at: R3.componentIndex)
                    let rBase4 = table.base(R4.self, at: R4.componentIndex)
                    let wBase1 = table.base(W1.self, at: W1.componentIndex)
                    let wBase2 = table.base(W2.self, at: W2.componentIndex)
                    let wBase3 = table.base(W3.self, at: W3.componentIndex)
                    let wBase4 = table.base(W4.self, at: W4.componentIndex)
                    for row in 0 ..< count {
                        visited += 1
                        try body(rBase1[row], rBase2[row], rBase3[row], rBase4[row], &wBase1[row], &wBase2[row], &wBase3[row], &wBase4[row])
                    }
                }
            }
        }
    }
}
