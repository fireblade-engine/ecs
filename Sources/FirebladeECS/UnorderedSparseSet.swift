//
//  UnorderedSparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public struct UnorderedSparseSet<Element> {
    public typealias Index = Int
    public typealias Key = Int

    public struct Entry {
        public let key: Key
        public let element: Element
    }

    @usableFromInline var dense: ContiguousArray<Entry>
    @usableFromInline var sparse: [Index: Key]

    public init() {
        self.init(sparse: [:], dense: [])
    }

    init(sparse: [Index: Key], dense: ContiguousArray<Entry>) {
        self.sparse = sparse
        self.dense = dense
    }

    public var count: Int { dense.count }
    public var isEmpty: Bool { dense.isEmpty }

    @inlinable
    public func contains(_ key: Key) -> Bool {
        find(at: key) != nil
    }

    /// Inset an element for a given key into the set in O(1).
    /// Elements at previously set keys will be replaced.
    ///
    /// - Parameters:
    ///   - element: the element
    ///   - key: the key
    /// - Returns: true if new, false if replaced.
    @discardableResult
    public mutating func insert(_ element: Element, at key: Key) -> Bool {
        if let (denseIndex, _) = find(at: key) {
            dense[denseIndex] = Entry(key: key, element: element)
            return false
        }

        let nIndex = dense.count
        dense.append(Entry(key: key, element: element))
        sparse[key] = nIndex
        return true
    }

    /// Get the element for the given key in O(1).
    ///
    /// - Parameter key: the key
    /// - Returns: the element or nil of key not found.
    @inlinable
    public func get(at key: Key) -> Element? {
        guard let (_, element) = find(at: key) else {
            return nil
        }

        return element
    }

    @inlinable
    public func get(unsafeAt key: Key) -> Element {
        find(at: key).unsafelyUnwrapped.1
    }

    /// Removes the element entry for given key in O(1).
    ///
    /// - Parameter key: the key
    /// - Returns: removed value or nil if key not found.
    @discardableResult
    public mutating func remove(at key: Key) -> Entry? {
        guard let (denseIndex, _) = find(at: key) else {
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

    @inlinable
    public mutating func removeAll(keepingCapacity: Bool = false) {
        sparse.removeAll(keepingCapacity: keepingCapacity)
        dense.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes an element from the set and retuns it in O(1).
    /// The removed element is replaced with the last element of the set.
    ///
    /// - Parameter denseIndex: the dense index
    /// - Returns: the element entry
    private mutating func swapRemove(at denseIndex: Int) -> Entry {
        dense.swapAt(denseIndex, dense.count - 1)
        return dense.removeLast()
    }

    @inlinable
    public func find(at key: Key) -> (Int, Element)? {
        guard let denseIndex = sparse[key], denseIndex < count else {
            return nil
        }
        let entry = self.dense[denseIndex]
        guard entry.key == key else {
            return nil
        }

        return (denseIndex, entry.element)
    }

    @inlinable
    public subscript(position: Index) -> Element {
        get {
            get(unsafeAt: position)
        }

        set(newValue) {
            insert(newValue, at: position)
        }
    }

    @inlinable public var first: Element? {
        dense.first?.element
    }

    @inlinable public var last: Element? {
        dense.last?.element
    }
}

// MARK: - Sequence
extension UnorderedSparseSet: Sequence {
    public __consuming func makeIterator() -> ElementIterator {
        ElementIterator(self)
    }

    // MARK: - UnorderedSparseSetIterator
    public struct ElementIterator: IteratorProtocol {
        public private(set) var iterator: IndexingIterator<ContiguousArray<UnorderedSparseSet<Element>.Entry>>

        public init(_ sparseSet: UnorderedSparseSet<Element>) {
            iterator = sparseSet.dense.makeIterator()
        }

        public mutating func next() -> Element? {
            iterator.next()?.element
        }
    }
}

// MARK: - Equatable
extension UnorderedSparseSet.Entry: Equatable where Element: Equatable { }
extension UnorderedSparseSet: Equatable where Element: Equatable {
    public static func == (lhs: UnorderedSparseSet<Element>, rhs: UnorderedSparseSet<Element>) -> Bool {
        lhs.dense == rhs.dense && lhs.sparse == rhs.sparse
    }
}

// MARK: - Codable
extension UnorderedSparseSet.Entry: Codable where Element: Codable { }
extension UnorderedSparseSet: Codable where Element: Codable { }
