//
//  ManagedContiguousArray.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//

public protocol UniformStorage: class {
	associatedtype Element
	associatedtype Index

	var count: Int { get }

	func add(_ element: Element, at index: Index)
	func has(_ index: Index) -> Bool
	func get(at index: Index) -> Element?
	func remove(at index: Index)
	func clear(keepingCapacity: Bool)
}

public class ManagedContiguousArray: UniformStorage {
	public static var chunkSize: Int = 4096
	public typealias Index = Int
	public typealias Element = Any
	private var size: Int = 0
	private var store: ContiguousArray<Element?> = []

	public init(minCount: Int = chunkSize) {
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

	public func remove(at index: Index) {
		if store[index] != nil {
			size -= 1
		}
		store[index] = nil
		if size == 0 {
			clear()
		}
	}

	public func clear(keepingCapacity: Bool = false) {
		size = 0
		store.removeAll(keepingCapacity: keepingCapacity)
	}

	func needsToGrow(_ index: Index) -> Bool {
		return index > store.count - 1
	}

	func grow(including index: Index) {
		let newCapacity: Int = nearest(to: index)
		let newCount: Int = newCapacity - store.count
		for _ in 0..<newCount {
			store.append(nil)
		}
	}

	func nearest(to index: Index) -> Int {
		let delta = Float(index) / Float(ManagedContiguousArray.chunkSize)
		let multiplier = Int(delta) + 1
		return multiplier * ManagedContiguousArray.chunkSize
	}
}

public class ContiguousComponentArray: ManagedContiguousArray {
	public typealias Element = Component
	public typealias Index = EntityIndex
}

public class ContiguousEntityIdArray: ManagedContiguousArray {
	public typealias Element = EntityIdentifier
}
