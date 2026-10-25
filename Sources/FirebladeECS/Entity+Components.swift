//
//  Entity+Components.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

// The overloads of `components(_:writing:)` for 0 to 4 read and 0 to 4 written component types are generated into
// Generated/Entity+Components.generated.swift by Scripts/generate-read-write-api.sh.

extension Entity {
    /// Reports why a multi component access of this entity found a component missing.
    @usableFromInline
    func reportMissingForAccess() -> Bool {
        if !nexus.isAlive(identifier) {
            nexus.reportStaleHandle(identifier)
        }
        return false
    }
}

// MARK: - parameter pack fallback

extension Entity {
    /// Changes any number of components of this entity in place, reading any number of others.
    ///
    /// This is the fallback for more than 4 read or 4 written types, which the overloads with fixed arity serve.
    /// Their contract applies (see the overload that reads 1 and writes 1 type), with two differences in shape:
    /// - `body` receives the written components first, as one `inout` tuple, then the read components. Swift can not
    ///   express `inout` pack parameters in a closure, and two packs in one closure type can not be inferred.
    /// - The written components are copied out of the nexus into the tuple and back after `body` returned. A
    ///   ``ComponentModified`` event is delivered for each written component after the write access ended.
    ///
    /// - Returns: `false` if this entity is destroyed or lacks one of the components; `body` is not called then.
    @discardableResult
    @_disfavoredOverload
    public func components<each R: Component, each W: Component>(
        _ rTypes: repeat (each R).Type,
        writing wTypes: repeat (each W).Type,
        body: (inout (repeat each W), repeat each R) throws -> Void
    ) rethrows -> Bool {
        var complete = true
        _ = (repeat complete = complete && has((each R).self))
        _ = (repeat complete = complete && has((each W).self))
        guard complete else {
            return reportMissingForAccess()
        }
        let reads = (repeat get((each R).self).unsafelyUnwrapped)
        let pointers = (repeat nexus.beginModify((each W).self, for: identifier).unsafelyUnwrapped)
        var written = (repeat (each pointers).pointee)
        func finish() {
            _ = (repeat Self.store(each written, to: each pointers))
            _ = (repeat nexus.endModify((each W).self, for: identifier))
        }
        do {
            try body(&written, repeat each reads)
        } catch {
            finish()
            throw error
        }
        finish()
        return true
    }

    @usableFromInline
    static func store<T: Component>(_ value: T, to pointer: UnsafeMutablePointer<T>) {
        pointer.pointee = value
    }
}
