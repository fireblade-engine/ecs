//
//  UnorderedSparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

/// An (unordered) sparse set.
///
/// - `Element`: the element (instance) to store.
/// - `Key`: the unique, hashable datastructure to use as a key to retrieve
///          an element from the sparse set.
///
/// See <https://github.com/bombela/sparseset/blob/master/src/lib.rs> for a reference implementation.
public struct UnorderedSparseSet<Element, Key: Hashable & Codable> {
    // swiftlint:disable nesting
    @usableFromInline
    final class Storage {
        /// An index into the dense store.
        @usableFromInline
        typealias DenseIndex = Int

        /// A sparse store holding indices into the dense mapped to key.
        @usableFromInline
        typealias SparseStore = [Key: DenseIndex]

        /// A dense store holding all the entries.
        @usableFromInline
        typealias DenseStore = ContiguousArray<Entry>

        @usableFromInline
        struct Entry {
            @usableFromInline let key: Key
            @usableFromInline let element: Element

            @usableFromInline
            init(key: Key, element: Element) {
                self.key = key
                self.element = element
            }
        }

        @usableFromInline var dense: DenseStore
        @usableFromInline var sparse: SparseStore

        @usableFromInline
        init(sparse: SparseStore, dense: DenseStore) {
            self.sparse = sparse
            self.dense = dense
        }

        @usableFromInline
        convenience init() {
            self.init(sparse: [:], dense: [])
        }

        @usableFromInline var count: Int { dense.count }
        @usableFromInline var isEmpty: Bool { dense.isEmpty }

        @inlinable var first: Element? {
            dense.first?.element
        }

        @inlinable
        func findIndex(at key: Key) -> Int? {
            guard let denseIndex = sparse[key], denseIndex < count else {
                return nil
            }
            return denseIndex
        }

        @inlinable
        func findElement(at key: Key) -> Element? {
            guard let denseIndex = findIndex(at: key) else {
                return nil
            }
            let entry = self.dense[denseIndex]
            assert(entry.key == key, "entry.key and findIndex(at: key) must be equal!")
            return entry.element
        }

        @inlinable
        func insert(_ element: Element, at key: Key) -> Bool {
            if let denseIndex = findIndex(at: key) {
                dense[denseIndex] = Entry(key: key, element: element)
                return false
            }

            let nIndex = dense.count
            dense.append(Entry(key: key, element: element))
            sparse.updateValue(nIndex, forKey: key)
            return true
        }

        @inlinable
        func remove(at key: Key) -> Entry? {
            guard let denseIndex = findIndex(at: key) else {
                return nil
            }

            let removed = swapRemove(at: denseIndex)
            if !dense.isEmpty && denseIndex < dense.count {
                let swappedElement = dense[denseIndex]
                sparse[swappedElement.key] = denseIndex
            }
            sparse[key] = nil
            return removed
        }

        /// Removes an element from the set and returns it in O(1).
        /// The removed element is replaced with the last element of the set.
        ///
        /// - Parameter denseIndex: the dense index
        /// - Returns: the element entry
        @inlinable
        func swapRemove(at denseIndex: Int) -> Entry {
            dense.swapAt(denseIndex, dense.count - 1)
            return dense.removeLast()
        }

        @inlinable
        func removeAll(keepingCapacity: Bool = false) {
            sparse.removeAll(keepingCapacity: keepingCapacity)
            dense.removeAll(keepingCapacity: keepingCapacity)
        }

        @inlinable
        func makeIterator() -> IndexingIterator<ContiguousArray<Storage.Entry>> {
            dense.makeIterator()
        }
    }

    public init() {
        self.init(storage: Storage())
    }

    @usableFromInline
    init(storage: Storage) {
        self.storage = storage
    }

    @usableFromInline let storage: Storage

    public var count: Int { storage.count }
    public var isEmpty: Bool { storage.isEmpty }

    @inlinable
    public func contains(_ key: Key) -> Bool {
        storage.findIndex(at: key) != nil
    }

    /// Inset an element for a given key into the set in O(1).
    /// Elements at previously set keys will be replaced.
    ///
    /// - Parameters:
    ///   - element: the element
    ///   - key: the key
    /// - Returns: true if new, false if replaced.
    @discardableResult
    public func insert(_ element: Element, at key: Key) -> Bool {
        storage.insert(element, at: key)
    }

    /// Get the element for the given key in O(1).
    ///
    /// - Parameter key: the key
    /// - Returns: the element or nil of key not found.
    @inlinable
    public func get(at key: Key) -> Element? {
        storage.findElement(at: key)
    }

    @inlinable
    public func get(unsafeAt key: Key) -> Element {
        storage.findElement(at: key).unsafelyUnwrapped
    }

    /// Removes the element entry for given key in O(1).
    ///
    /// - Parameter key: the key
    /// - Returns: removed value or nil if key not found.
    @discardableResult
    public func remove(at key: Key) -> Element? {
        storage.remove(at: key)?.element
    }

    @inlinable
    public func removeAll(keepingCapacity: Bool = false) {
        storage.removeAll(keepingCapacity: keepingCapacity)
    }

    @inlinable public var first: Element? {
        storage.first
    }
}

extension UnorderedSparseSet where Key == Int {
    @inlinable
    public subscript(key: Key) -> Element {
        get {
            get(unsafeAt: key)
        }

        nonmutating set(newValue) {
            insert(newValue, at: key)
        }
    }
}

// MARK: - Sequence
extension UnorderedSparseSet: Sequence {
    public func makeIterator() -> ElementIterator {
        ElementIterator(self)
    }

    // MARK: - UnorderedSparseSetIterator
    public struct ElementIterator: IteratorProtocol {
        var iterator: IndexingIterator<ContiguousArray<Storage.Entry>>

        public init(_ sparseSet: UnorderedSparseSet<Element, Key>) {
            iterator = sparseSet.storage.makeIterator()
        }

        public mutating func next() -> Element? {
            iterator.next()?.element
        }
    }
}

// MARK: - Equatable
extension UnorderedSparseSet.Storage.Entry: Equatable where Element: Equatable { }
extension UnorderedSparseSet.Storage: Equatable where Element: Equatable {
    @usableFromInline
    static func == (lhs: UnorderedSparseSet<Element, Key>.Storage, rhs: UnorderedSparseSet<Element, Key>.Storage) -> Bool {
        lhs.dense == rhs.dense && lhs.sparse == rhs.sparse
    }
}
extension UnorderedSparseSet: Equatable where Element: Equatable {
    public static func == (lhs: UnorderedSparseSet<Element, Key>, rhs: UnorderedSparseSet<Element, Key>) -> Bool {
        lhs.storage == rhs.storage
    }
}

// MARK: - Codable
extension UnorderedSparseSet.Storage.Entry: Codable where Element: Codable { }
extension UnorderedSparseSet.Storage: Codable where Element: Codable { }
extension UnorderedSparseSet: Codable where Element: Codable { }
