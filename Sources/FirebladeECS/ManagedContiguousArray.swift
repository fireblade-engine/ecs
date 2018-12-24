//
//  ManagedContiguousArray.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//

public protocol UniformStorage: AnyObject {
	associatedtype Element
	associatedtype Index

	var count: Int { get }

	func add(_ element: Element, at index: Index)
	func has(_ index: Index) -> Bool
	func get(at index: Index) -> Element?
	@discardableResult
	func remove(at index: Index) -> Bool
	func clear(keepingCapacity: Bool)
}

public class ManagedContiguousArray<Element>: UniformStorage {
	public typealias Index = Int
    private let chunkSize: Int
	private var size: Int = 0
	private var store: ContiguousArray<Element?> = []

	public init(minCount: Int = 4096) {
        chunkSize = minCount
		store = ContiguousArray<Element?>(repeating: nil, count: minCount)
	}

	deinit {
		clear()
	}

	public var count: Int {
		return size
	}

	public func add(_ element: Element, at index: Index) {
		if needsToGrow(index) {
			grow(including: index)
		}
		if store[index] == nil {
			size += 1
		}
		store[index] = element
	}
	public func has(_ index: Index) -> Bool {
		if store.count <= index {
			return false
		}
		return store[index] != nil
	}

	public func get(at index: Index) -> Element? {
		return store[index]
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

	private func grow(including index: Index) {
		let newCapacity: Int = nearest(to: index)
		let newCount: Int = newCapacity - store.count
		for _ in 0..<newCount {
			store.append(nil)
		}
	}

	private func nearest(to index: Index) -> Int {
        let delta = Float(index) / Float(chunkSize)
        let multiplier = Int(delta) + 1
		return multiplier * chunkSize
	}
}

// MARK: - Equatable
extension ManagedContiguousArray: Equatable where ManagedContiguousArray.Element: Equatable {
    public static func == (lhs: ManagedContiguousArray<Element>, rhs: ManagedContiguousArray<Element>) -> Bool {
        return lhs.store == rhs.store
    }
}
