//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseSet<Element>: Sequence {
    public typealias Index = Int
    public typealias Key = Int

    public struct Entry {
        let key: Key
        let element: Element
    }

    private(set) var dense: ContiguousArray<Entry>
    private(set) var sparse: [Index: Key]

    // TODO: implement
    // a) RandomAccessCollection conformance
    // b) subscript

    public init() {
        sparse = [Index: Key]()
        dense = ContiguousArray<Entry>()
    }

    deinit {
        clear()
    }

    public var count: Int { return dense.count }
    public var isEmpty: Bool { return dense.isEmpty }
    public var capacity: Int { return sparse.count }

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
    public func get(at key: Key) -> Element? {
        guard let (_, element) = find(at: key) else {
            return nil
        }

        return element
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

    public func clear(keepingCapacity: Bool = false) {
        sparse.removeAll(keepingCapacity: keepingCapacity)
        dense.removeAll(keepingCapacity: keepingCapacity)
    }

    public func makeIterator() -> SparseSetIterator<Element> {
        return SparseSetIterator<Element>(self)
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

    private func find(at key: Key) -> (Int, Element)? {
        guard let denseIndex = sparse[key], denseIndex < count else {
            return nil
        }
        let entry = self.dense[denseIndex]
        guard entry.key == key else {
            return nil
        }

        return (denseIndex, entry.element)
    }

    // MARK: - SparseIterator
    public struct SparseSetIterator<Element>: IteratorProtocol {
        private let sparseSet: SparseSet<Element>
        private var sortedSparseIterator: IndexingIterator<[(key: SparseSet.Index, value: SparseSet.Key)]>

        init(_ sparseSet: SparseSet<Element>) {
            self.sparseSet = sparseSet

            let sortedSparse = sparseSet.sparse.sorted { first, next -> Bool in
                first.key < next.key
            }

            sortedSparseIterator = sortedSparse.makeIterator()
        }

        mutating public func next() -> Element? {
            guard let (key, _) = sortedSparseIterator.next() else {
                return nil
            }

            return sparseSet.get(at: key)

        }

    }
}

extension SparseSet.Entry: Equatable where SparseSet.Element: Equatable {
    public static func == (lhs: SparseSet.Entry, rhs: SparseSet.Entry) -> Bool {
        return lhs.element == rhs.element && lhs.key == rhs.key
    }
}

// MARK: - Equatable
extension SparseSet: Equatable where SparseSet.Element: Equatable {
    public static func == (lhs: SparseSet<Element>, rhs: SparseSet<Element>) -> Bool {
        return lhs.dense == rhs.dense &&
            lhs.sparse == rhs.sparse
    }
}

// MARK: - specialized sparse sets

public class SparseEntitySet: SparseSet<Entity> {
    public typealias Index = EntityIndex
}

public class SparseEntityIdentifierSet: SparseSet<EntityIdentifier> {
    public typealias Index = EntityIndex

}

public class SparseComponentIdentifierSet: SparseSet<ComponentIdentifier> {

}
