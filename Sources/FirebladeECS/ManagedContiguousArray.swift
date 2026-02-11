///
///  ManagedContiguousArray.swift
///  FirebladeECS
///
///  Created by Christian Treffs on 28.10.17.
///
/// A type that provides a managed contiguous array of elements that you provide.
public struct ManagedContiguousArray<Element> {
    public typealias Index = Int

    @usableFromInline let chunkSize: Int
    @usableFromInline var size: Int = 0
    @usableFromInline var store: ContiguousArray<Element?> = []

    /// Creates a new array.
    /// - Parameter minCount: The minimum number of elements, which defaults to `4096`.
    public init(minCount: Int = 4096) {
        chunkSize = minCount
        store = ContiguousArray<Element?>(repeating: nil, count: minCount)
    }

    /// The number of elements in the array.
    @inline(__always)
    public var count: Int {
        size
    }

    /// Inserts an element into the managed array.
    /// - Parameters:
    ///   - element: The element to insert
    ///   - index: The location at which to insert the element.
    /// - Returns: `true` to indicate the element was inserted.
    @discardableResult
    @inlinable
    public mutating func insert(_ element: Element, at index: Int) -> Bool {
        if needsToGrow(index) {
            grow(to: index)
        }
        if store[index] == nil {
            size += 1
        }
        store[index] = element
        return true
    }

    /// Returns a Boolean value that indicates whether the index location holds an element.
    /// - Parameter index: The index location in the contiguous array to inspect.
    @inlinable
    public func contains(_ index: Index) -> Bool {
        if store.count <= index {
            return false
        }
        return store[index] != nil
    }

    /// Retrieves the value at the index location you provide.
    /// - Parameter index: The index location.
    /// - Returns: The element at the index location, or `nil`.
    @inline(__always)
    public func get(at index: Index) -> Element? {
        store[index]
    }

    /// Unsafely retrieves the value at the index location you provide.
    /// - Parameter index: The index location.
    /// - Returns: The element at the index location.
    @inline(__always)
    public func get(unsafeAt index: Index) -> Element {
        store[index].unsafelyUnwrapped
    }

    /// Removes the object at the index location you provide.
    /// - Parameter index: The index location.
    /// - Returns: `true` to indicate the element was removed.
    @discardableResult
    @inlinable
    public mutating func remove(at index: Index) -> Bool {
        if store[index] != nil {
            size -= 1
        }
        store[index] = nil
        if size == 0 {
            clear()
        }
        return true
    }

    /// Clears the array of all elements.
    /// - Parameter keepingCapacity: A Boolean value that indicates whether to keep the capacity of the array.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = false) {
        size = 0
        store.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Returns a Boolean value that indicates if the array needs to grow to insert another item.
    /// - Parameter index: The index location to check.
    @inlinable
    func needsToGrow(_ index: Index) -> Bool {
        index > store.count - 1
    }

    /// Expands the contiguous array to encompass the index location you provide.
    /// - Parameter index: The index location.
    @inlinable
    mutating func grow(to index: Index) {
        let newCapacity: Int = calculateCapacity(to: index)
        let newCount: Int = newCapacity - store.count
        store += ContiguousArray<Element?>(repeating: nil, count: newCount)
    }

    /// Returns the capacity of the array to the index location you provide.
    /// - Parameter index: The index location
    @inlinable
    func calculateCapacity(to index: Index) -> Int {
        let delta = Float(index) / Float(chunkSize)
        let multiplier = Int(delta.rounded(.up)) + 1
        return multiplier * chunkSize
    }
}

// MARK: - Equatable

extension ManagedContiguousArray: Equatable where Element: Equatable {
    public static func == (lhs: ManagedContiguousArray<Element>, rhs: ManagedContiguousArray<Element>) -> Bool {
        lhs.store == rhs.store
    }
}

// MARK: - Codable

extension ManagedContiguousArray: Codable where Element: Codable {}

extension ManagedContiguousArray: Sendable where Element: Sendable {}
