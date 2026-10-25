//
//  ComponentIndex.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

#if canImport(Foundation)
    import Foundation
#endif

extension Component {
    /// The dense index of this component type.
    ///
    /// Storages address their per-type state and the per-entity component bitset by this value.
    ///
    /// The default implementation assigns indices lazily: the first access of a type takes the next free index
    /// of the process, later accesses look it up in a thread-safe table. The index is process-wide, not per ``Nexus``,
    /// so all nexuses of a process agree on it. Indices are dense (`0 ..< n` for `n` types used so far) and unbounded.
    /// They depend on the order of first use and are not stable between process launches;
    /// use ``RegistrableComponent/stableIdentifier`` for persistent data.
    ///
    /// Swift has no stored static properties in generic types, so a plain conformance can not cache its index in a static.
    /// Provide your own implementation (the `@Component` macro will) as a stored `static let` for a plain load,
    /// but only if you can guarantee that two types never share an index.
    /// - Complexity: O(1)
    public static var componentIndex: Int {
        Nexus.ComponentIndexRegistry.shared.index(of: Self.self)
    }
}

extension Nexus {
    /// Assigns dense component indices to component types, once per type and process.
    @usableFromInline
    final class ComponentIndexRegistry: @unchecked Sendable {
        @usableFromInline static let shared = ComponentIndexRegistry()

        private var indexByType: [ObjectIdentifier: Int] = [:]

        #if canImport(Foundation)
            private let lock = NSLock()
        #endif

        private init() {}

        /// The number of component types that have an index.
        @usableFromInline var count: Int {
            #if canImport(Foundation)
                lock.lock()
                defer { lock.unlock() }
            #endif
            return indexByType.count
        }

        /// The index of a component type; takes the next free index on first use.
        /// - Parameter type: The component type.
        /// - Returns: The same index for every call with the same type.
        /// - Complexity: O(1)
        @usableFromInline
        func index(of type: any Component.Type) -> Int {
            #if canImport(Foundation)
                lock.lock()
                defer { lock.unlock() }
            #endif
            let key = ObjectIdentifier(type)
            if let existing = indexByType[key] {
                return existing
            }
            let index = indexByType.count
            indexByType[key] = index
            return index
        }
    }
}
