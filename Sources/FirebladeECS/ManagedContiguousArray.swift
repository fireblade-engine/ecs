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
	var _size: Int = 0
	var _store: ContiguousArray<Element?> = []
	public init(minCount: Int = chunkSize) {
		_store = ContiguousArray<Element?>(repeating: nil, count: minCount)
	}
	deinit {
		clear()
	}

	public var count: Int {
		return _size
	}

	public func add(_ element: Element, at index: Index) {
		if needsToGrow(index) {
			grow(including: index)
		}
		if _store[index] == nil {
			_size += 1
		}
		_store[index] = element
	}
	public func has(_ index: Index) -> Bool {
		if _store.count <= index { return false }
		return _store[index] != nil
	}

	public func get(at index: Index) -> Element? {
		return _store[index]
	}

	public func remove(at index: Index) {
		if _store[index] != nil {
			_size -= 1
		}
		_store[index] = nil
		if _size == 0 {
			clear()
		}
	}

	public func clear(keepingCapacity: Bool = false) {
		_size = 0
		_store.removeAll(keepingCapacity: keepingCapacity)
	}

	internal func needsToGrow(_ index: Index) -> Bool {
		return index > _store.count - 1
	}

	internal func grow(including index: Index) {
		let newCapacity: Int = nearest(to: index)
		let newCount: Int = newCapacity-_store.count
		for _ in 0..<newCount {
			_store.append(nil)
		}
	}

	internal func nearest(to index: Index) -> Int {
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
