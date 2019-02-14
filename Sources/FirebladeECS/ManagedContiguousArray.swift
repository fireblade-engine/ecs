//
//  ManagedContiguousArray.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//

public class ManagedContiguousArray<Element>: UniformStorage {
    public typealias Index = Int
    private let chunkSize: Int
    private var size: Int = 0
    private var store: ContiguousArray<Element?> = []

    public init(minCount: Int = 4096) {
        chunkSize = MemoryLayout<Element>.stride * 512
        store = ContiguousArray<Element?>(repeating: nil, count: minCount)
    }

    deinit {
        clear()
    }

    public var count: Int {
        return size
    }

    @discardableResult
    public func insert(_ element: Element, at index: Int) -> Bool {
        if needsToGrow(index) {
            grow(to: index)
        }
        if store[index] == nil {
            size += 1
        }
        store[index] = element
        return true
    }
    public func contains(_ index: Index) -> Bool {
        if store.count <= index {
            return false
        }
        return store[index] != nil
    }

    public func get(at index: Index) -> Element? {
        return store[index]
    }

    public func get(unsafeAt index: Index) -> Element {
        return store[index].unsafelyUnwrapped
    }

    @discardableResult
    public func remove(at index: Index) -> Bool {
        if store[index] != nil {
            size -= 1
        }
        store[index] = nil
        if size == 0 {
            clear()
        }
        return true
    }

    public func clear(keepingCapacity: Bool = false) {
        size = 0
        store.removeAll(keepingCapacity: keepingCapacity)
    }

    private func needsToGrow(_ index: Index) -> Bool {
        return index > store.count - 1
    }

    private func grow(to index: Index) {
        let newCapacity: Int = calculateCapacity(to: index)
        let newCount: Int = newCapacity - store.count
        store += ContiguousArray<Element?>(repeating: nil, count: newCount)
    }

    private func calculateCapacity(to index: Index) -> Int {
        let delta = Float(index) / Float(chunkSize)
        let multiplier = Int(delta.rounded(.up)) + 1
        return multiplier * chunkSize
    }
}

// MARK: - Equatable
extension ManagedContiguousArray: Equatable where ManagedContiguousArray.Element: Equatable {
    public static func == (lhs: ManagedContiguousArray<Element>, rhs: ManagedContiguousArray<Element>) -> Bool {
        return lhs.store == rhs.store
    }
}
