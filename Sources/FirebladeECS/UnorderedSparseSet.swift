//
//  UnorderedSparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

open class UnorderedSparseSet<Element>: MutableCollection, RandomAccessCollection {
    public typealias Index = Int
    public typealias Key = Int

    public struct Entry {
        public let key: Key
        public let element: Element
    }

    public private(set) var dense: ContiguousArray<Entry>
    public private(set) var sparse: [Index: Key]

    public init() {
        sparse = [Index: Key]()
        dense = ContiguousArray<Entry>()
    }

    deinit {
        removeAll()
    }

    public var count: Int { return dense.count }
    public var isEmpty: Bool { return dense.isEmpty }
    public var capacity: Int { return sparse.count }

    @inlinable
    public func contains(_ key: Key) -> Bool {
        return find(at: key) != nil
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
        return find(at: key).unsafelyUnwrapped.1
    }

    /// Removes the element entry for given key in O(1).
    ///
    /// - Parameter key: the key
    /// - Returns: removed value or nil if key not found.
    @discardableResult
    public func remove(at key: Key) -> Entry? {
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
    public func removeAll(keepingCapacity: Bool = false) {
        sparse.removeAll(keepingCapacity: keepingCapacity)
        dense.removeAll(keepingCapacity: keepingCapacity)
    }

    @inlinable
    public func makeIterator() -> UnorderedSparseSetIterator<Element> {
        return UnorderedSparseSetIterator<Element>(self)
    }

    /// Removes an element from the set and retuns it in O(1).
    /// The removed element is replaced with the last element of the set.
    ///
    /// - Parameter denseIndex: the dense index
    /// - Returns: the element entry
    private func swapRemove(at denseIndex: Int) -> Entry {
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

    // MARK: Collection
    @inlinable
    public func index(after index: Index) -> Int {
        return dense.index(after: index)
    }

    @inlinable
    public subscript(position: Index) -> Element {
        get {
            guard let element: Element = get(at: position) else {
                fatalError("no element at index \(position)")
            }
            return element
        }

        set(newValue) {
            insert(newValue, at: position)
        }
    }

    @inlinable public var startIndex: Index {
        return dense.startIndex
    }

    @inlinable public var endIndex: Index {
        return dense.endIndex
    }
}

extension UnorderedSparseSet.Entry: Equatable where UnorderedSparseSet.Element: Equatable { }

extension UnorderedSparseSet: Equatable where UnorderedSparseSet.Element: Equatable {
    public static func == (lhs: UnorderedSparseSet<Element>, rhs: UnorderedSparseSet<Element>) -> Bool {
        return lhs.dense == rhs.dense && lhs.sparse == rhs.sparse
    }
}

// MARK: - UnorderedSparseSetIterator
public struct UnorderedSparseSetIterator<Element>: IteratorProtocol {
    public private(set) var iterator: IndexingIterator<ContiguousArray<UnorderedSparseSet<Element>.Entry>>

    public init(_ sparseSet: UnorderedSparseSet<Element>) {
        iterator = sparseSet.dense.makeIterator()
    }

    public mutating func next() -> Element? {
        return iterator.next()?.element
    }
}
