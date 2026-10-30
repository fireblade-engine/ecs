//
//  ComponentIndex.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 25.10.26.
//

import CFirebladeAtomics
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
        registeredComponentIndex
    }

    /// The index the process-wide registry assigns to this component type, taking the next free one on first access.
    ///
    /// Use it to cache the index in a stored `static let`, which is what the `@Component` macro generates:
    ///
    /// ```swift
    /// static let componentIndex = registeredComponentIndex
    /// ```
    ///
    /// Typed lookups then read a plain static instead of taking the registry lock. A type that caches the
    /// registry's index can never collide with a lazily assigned one.
    /// - Complexity: O(1)
    public static var registeredComponentIndex: Int {
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
    ///
    /// Reads of registered types are lock-free and wait-free; only the first use of a type takes the lock.
    ///
    /// The registry keeps an open-addressing hash table (power-of-two capacity, load factor at most 0.5,
    /// linear probing, multiply-shift hash of the type's ``ObjectIdentifier``) behind an atomic pointer.
    /// A table is laid out as words: `[capacity, shift, (key, index) × capacity]`; a key of `0` marks an empty slot
    /// (no metatype has address 0). Entries are never removed or changed once published:
    ///
    /// - A reader acquire-loads the table pointer and probes with acquire-loads of the key words.
    ///   A key match returns the index, an empty slot means a miss, and a miss falls back to the locked path.
    /// - A writer holds the lock, re-checks, writes the index word and then release-stores the key word, so a reader
    ///   that sees the key also sees its index. When the table would exceed half full, the writer builds a table of
    ///   twice the capacity privately and release-stores its pointer.
    ///
    /// Superseded tables are never freed, so a reader that loaded an old pointer can never touch freed memory.
    /// They are kept alive by the registry, which is a process-lifetime singleton. Capacity doubles, so all retired
    /// tables together are smaller than the current one: memory stays within about 3x the final table
    /// (`32 * 2^ceil(log2(2n))` bytes for `n` types on 64-bit platforms; 16 KiB for 256 types).
    /// A reader on an old table may miss a type added later; it then takes the lock and sees the current table.
    @usableFromInline
    final class ComponentIndexRegistry: @unchecked Sendable {
        @usableFromInline static let shared = ComponentIndexRegistry()

        /// The exclusive upper bound of component indices, assigned or user-supplied.
        ///
        /// Storages keep an array that grows to the highest index, and entity bitsets grow to it as well,
        /// so absurd indices are rejected instead of allocating gigabytes.
        @usableFromInline static let indexLimit = 1 << 20

        private static let initialCapacity = 16
        private static let headerWords = 2
        @usableFromInline static let hashMultiplier = UInt(truncatingIfNeeded: 0x9E37_79B9_7F4A_7C15 as UInt64)

        /// A single word holding the address of the current table. Accessed only through acquire/release atomics.
        @usableFromInline let current: UnsafeMutablePointer<UInt>
        /// Guards `retired`, `assigned` and all table mutation.
        private let lock = Lock()
        private var retired: [UnsafeMutablePointer<UInt>] = []
        private var assigned = 0

        private init() {
            current = .allocate(capacity: 1)
            current.initialize(to: UInt(bitPattern: Self.makeTable(capacity: Self.initialCapacity)))
        }

        /// The number of component types that have an index.
        @usableFromInline var count: Int {
            lock.withLock { assigned }
        }

        /// The index of a component type; takes the next free index on first use.
        /// - Parameter type: The component type.
        /// - Returns: The same index for every call with the same type.
        /// - Complexity: O(1) for a registered type, lock-free and wait-free in practice (probe length is bounded by the load factor).
        @inlinable
        func index(of type: any Component.Type) -> Int {
            let key = UInt(bitPattern: ObjectIdentifier(type))
            if let found = Self.lookup(key, in: UnsafeMutablePointer<UInt>(bitPattern: frb_load_acquire(current)).unsafelyUnwrapped) {
                return found
            }
            return register(key)
        }

        @inlinable
        static func lookup(_ key: UInt, in table: UnsafeMutablePointer<UInt>) -> Int? {
            let mask = Int(bitPattern: table[0]) &- 1
            var slot = Int(bitPattern: (key &* hashMultiplier) >> table[1]) & mask
            while true {
                let entry = table + (2 &+ 2 &* slot)
                let stored = frb_load_acquire(entry)
                if stored == key {
                    return Int(bitPattern: entry[1])
                }
                if stored == 0 {
                    return nil
                }
                slot = (slot &+ 1) & mask
            }
        }

        @usableFromInline
        func register(_ key: UInt) -> Int {
            lock.withLock {
                var table = UnsafeMutablePointer<UInt>(bitPattern: current.pointee).unsafelyUnwrapped
                if let existing = Self.lookup(key, in: table) {
                    return existing
                }
                let index = assigned
                precondition(index < Self.indexLimit, "too many component types")
                if (index + 1) * 2 > Int(bitPattern: table[0]) {
                    let grown = Self.makeTable(capacity: Int(bitPattern: table[0]) * 2, copying: table)
                    retired.append(table)
                    table = grown
                    // The grown table is complete, so publishing it first lets readers pick it up before the new key lands.
                    frb_store_release(current, UInt(bitPattern: grown))
                }
                Self.insert(key, index, into: table, publish: true)
                assigned += 1
                return index
            }
        }

        private static func makeTable(capacity: Int, copying old: UnsafeMutablePointer<UInt>? = nil) -> UnsafeMutablePointer<UInt> {
            let table = UnsafeMutablePointer<UInt>.allocate(capacity: headerWords + 2 * capacity)
            table.initialize(repeating: 0, count: headerWords + 2 * capacity)
            table[0] = UInt(capacity)
            table[1] = UInt(UInt.bitWidth - capacity.trailingZeroBitCount)
            if let old {
                for slot in 0 ..< Int(bitPattern: old[0]) {
                    let entry = old + (2 + 2 * slot)
                    if entry[0] != 0 {
                        insert(entry[0], Int(bitPattern: entry[1]), into: table, publish: false)
                    }
                }
            }
            return table
        }

        /// Inserts a key that is not in the table yet. The index word is written before the key word is release-stored.
        private static func insert(_ key: UInt, _ index: Int, into table: UnsafeMutablePointer<UInt>, publish: Bool) {
            let mask = Int(bitPattern: table[0]) - 1
            var slot = Int(bitPattern: (key &* hashMultiplier) >> table[1]) & mask
            while table[2 + 2 * slot] != 0 {
                slot = (slot + 1) & mask
            }
            let entry = table + (2 + 2 * slot)
            entry[1] = UInt(bitPattern: index)
            if publish {
                frb_store_release(entry, key)
            } else {
                entry[0] = key
            }
        }
    }
}
