//
//  Family+ReadWrite.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

// The fixed arity overloads of `forEach(reading:writing:)` (0 to 4 read, 0 to 4 written types) are generated into
// Generated/Family+ReadWrite.generated.swift by Scripts/generate-read-write-api.sh.

extension Family {
    /// Traps if `type` is not a required component of this family.
    ///
    /// The member list is the iteration domain, so only required types are guaranteed to exist for every member.
    @inlinable
    func requireRequired<T: Component>(_: T.Type) {
        precondition(traits.requiresAll.contains(T.identifier), "component type is not required by the family")
    }
}

// MARK: - parameter pack fallback

extension Family {
    /// Iterates the members of this family with any number of read and written component types.
    ///
    /// This is the fallback for more than 4 read or 4 written types; fewer are served by the overloads with fixed arity,
    /// which are faster because their loop specializes. The contract is the one of those overloads (see
    /// the overload that reads 1 and writes 1 type), with two differences in shape:
    /// - `body` receives the written components first, as one `inout` tuple, then the read components. Swift can not
    ///   express `inout` pack parameters in a closure, and two packs in one closure type can not be inferred.
    /// - The written components are copied out of the storage into the tuple and back after `body` returned, so a
    ///   write is not visible in the storage before `body` returns.
    ///
    /// ```swift
    /// family.forEach(reading: A.self, B.self, C.self, D.self, E.self, writing: X.self, Y.self) { (written: inout (X, Y), a, b, c, d, e) in
    ///     written.0.value += a.value
    /// }
    /// ```
    ///
    /// - Complexity: O(N) where N is the number of members, plus one hash lookup per component type.
    @inlinable
    public func forEach<each R: Component, each W: Component>(
        reading rTypes: repeat (each R).Type,
        writing wTypes: repeat (each W).Type,
        body: (inout (repeat each W), repeat each R) throws -> Void
    ) rethrows {
        guard case let .sparseSet(sparse) = nexus.backend else { return }
        _ = (repeat requireRequired((each R).self))
        _ = (repeat requireRequired((each W).self))
        let members = memberIds
        guard !members.isEmpty else { return }
        let optionalReads = (repeat sparse.existing((each R).self, at: (each R).componentIndex))
        let optionalWrites = (repeat sparse.existing((each W).self, at: (each W).componentIndex))
        var complete = true
        _ = (repeat complete = complete && (each optionalReads) != nil)
        _ = (repeat complete = complete && (each optionalWrites) != nil)
        guard complete else { return }
        let reads = (repeat (each optionalReads).unsafelyUnwrapped)
        let writes = (repeat (each optionalWrites).unsafelyUnwrapped)
        sparse.lockDepth += 1
        _ = (repeat sparse.beginWrite((each W).componentIndex))
        _ = (repeat sparse.requireReadable((each R).componentIndex))
        var visited = 0
        defer {
            _ = (repeat sparse.endWrite((each W).componentIndex))
            sparse.lockDepth -= 1
            if visited > 0 {
                _ = (repeat nexus.emitModified((each W).self, count: visited))
            }
        }
        let entries = members.storage.dense
        try entries.withUnsafeBufferPointer { entries in
            for entry in entries {
                let key = entry.key
                let readValues = (repeat Self.value(of: each reads, at: key))
                let writePointers = (repeat Self.address(in: each writes, at: key))
                var written = (repeat (each writePointers).pointee)
                defer {
                    _ = (repeat Self.store(each written, to: each writePointers))
                }
                try body(&written, repeat each readValues)
                visited += 1
            }
        }
    }

    @inlinable
    static func value<T: Component>(of storage: Nexus.ComponentStorage<T>, at key: UInt32) -> T {
        let slot = storage.slot(of: key)
        precondition(slot >= 0, "member without a required component")
        return storage[slot]
    }

    @inlinable
    static func address<T: Component>(in storage: Nexus.ComponentStorage<T>, at key: UInt32) -> UnsafeMutablePointer<T> {
        let slot = storage.slot(of: key)
        precondition(slot >= 0, "member without a required component")
        return storage.base + slot
    }

    @inlinable
    static func store<T: Component>(_ value: T, to pointer: UnsafeMutablePointer<T>) {
        pointer.pointee = value
    }
}
