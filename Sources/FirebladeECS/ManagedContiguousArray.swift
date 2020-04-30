//
//  ManagedContiguousArray.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//
public struct ManagedContiguousArray<Element> {
    public typealias Index = Int

    @usableFromInline let chunkSize: Int
    @usableFromInline var size: Int = 0
    @usableFromInline var store: ContiguousArray<Element?> = []

    public init(minCount: Int = 4096) {
        chunkSize = minCount
        store = ContiguousArray<Element?>(repeating: nil, count: minCount)
    }

    @inline(__always)
    public var count: Int {
        size
    }

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

    @inlinable
    public func contains(_ index: Index) -> Bool {
        if store.count <= index {
            return false
        }
        return store[index] != nil
    }

    @inline(__always)
    public func get(at index: Index) -> Element? {
        store[index]
    }

    @inline(__always)
    public func get(unsafeAt index: Index) -> Element {
        store[index].unsafelyUnwrapped
    }

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

    @inlinable
    public mutating func clear(keepingCapacity: Bool = false) {
        size = 0
        store.removeAll(keepingCapacity: keepingCapacity)
    }

    @inlinable
    func needsToGrow(_ index: Index) -> Bool {
        index > store.count - 1
    }

    @inlinable
    mutating func grow(to index: Index) {
        let newCapacity: Int = calculateCapacity(to: index)
        let newCount: Int = newCapacity - store.count
        store += ContiguousArray<Element?>(repeating: nil, count: newCount)
    }

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
extension ManagedContiguousArray: Codable where Element: Codable { }
