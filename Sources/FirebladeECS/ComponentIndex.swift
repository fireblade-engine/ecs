//
//  ComponentIndex.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

#if canImport(WinSDK)
    import WinSDK
#elseif canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Bionic)
    import Bionic
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
    /// but only if you can guarantee that two types never share an index and that it is in `0 ..< 1_048_576`.
    /// Indices are process-wide: a hand-assigned index must not collide with a lazily assigned one of another type.
    /// A collision or an index out of range traps at first use of the type in a nexus.
    /// - Complexity: O(1)
    public static var componentIndex: Int {
        Nexus.ComponentIndexRegistry.shared.index(of: Self.self)
    }
}

extension Nexus {
    /// A minimal mutual exclusion lock that exists on every platform with threads.
    ///
    /// Windows uses a slim reader/writer lock, other platforms a pthread mutex.
    /// WebAssembly (WASI) has no threads that share this module's memory, so locking is a no-op there.
    @usableFromInline
    final class Lock: @unchecked Sendable {
        #if os(Windows)
            private let handle = UnsafeMutablePointer<SRWLOCK>.allocate(capacity: 1)
        #elseif !os(WASI)
            private let handle = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        #endif

        @usableFromInline
        init() {
            #if os(Windows)
                InitializeSRWLock(handle)
            #elseif !os(WASI)
                pthread_mutex_init(handle, nil)
            #endif
        }

        deinit {
            #if !os(WASI)
                #if !os(Windows)
                    pthread_mutex_destroy(handle)
                #endif
                handle.deallocate()
            #endif
        }

        @usableFromInline
        func withLock<R>(_ body: () -> R) -> R {
            #if os(Windows)
                AcquireSRWLockExclusive(handle)
                defer { ReleaseSRWLockExclusive(handle) }
            #elseif !os(WASI)
                pthread_mutex_lock(handle)
                defer { pthread_mutex_unlock(handle) }
            #endif
            return body()
        }
    }

    /// Assigns dense component indices to component types, once per type and process.
    @usableFromInline
    final class ComponentIndexRegistry: @unchecked Sendable {
        @usableFromInline static let shared = ComponentIndexRegistry()

        /// The exclusive upper bound of component indices, assigned or user-supplied.
        ///
        /// Storages keep an array that grows to the highest index, and entity bitsets grow to it as well,
        /// so absurd indices are rejected instead of allocating gigabytes.
        @usableFromInline static let indexLimit = 1 << 20

        private var indexByType: [ObjectIdentifier: Int] = [:]
        private let lock = Lock()

        private init() {}

        /// The number of component types that have an index.
        @usableFromInline var count: Int {
            lock.withLock { indexByType.count }
        }

        /// The index of a component type; takes the next free index on first use.
        /// - Parameter type: The component type.
        /// - Returns: The same index for every call with the same type.
        /// - Complexity: O(1)
        @usableFromInline
        func index(of type: any Component.Type) -> Int {
            lock.withLock {
                let key = ObjectIdentifier(type)
                if let existing = indexByType[key] {
                    return existing
                }
                let index = indexByType.count
                precondition(index < Self.indexLimit, "too many component types")
                indexByType[key] = index
                return index
            }
        }
    }
}
