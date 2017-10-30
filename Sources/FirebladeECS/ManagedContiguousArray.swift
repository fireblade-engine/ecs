//
//  ManagedContiguousArray.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 28.10.17.
//

private let pow2: [Int] = [	1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 4294967296
]

private func nearestToPow2(_ value: Int) -> Int {
	let exp = (value.bitWidth-value.leadingZeroBitCount)
	return pow2[exp]
}

public protocol ManagedContiguousArrayProtocol: class {
	associatedtype Element
	static var chunkSize: Int { get }
	init(minCount: Int)
	var count: Int { get }
	func insert(_ element: Element, at index: Int)
	func has(_ index: Int) -> Bool
	func get(at index: Int) -> Element?
	func remove(at index: Int)
}

public class ManagedContiguousArray: ManagedContiguousArrayProtocol {
	public static var chunkSize: Int = 4096

	public typealias Element = Any
	var _count: Int = 0
	var _store: ContiguousArray<Element?> = []
	public required init(minCount: Int = chunkSize) {
		_store = ContiguousArray<Element?>(repeating: nil, count: minCount)
	}

	public var count: Int {
		return _count
	}

	public func insert(_ element: Element, at index: Int) {
		if needsToGrow(index) {
			grow(including: index)
		}
		if _store[index] == nil {
			_count += 1
		}
		_store[index] = element
	}
	public func has(_ index: Int) -> Bool {
		if _store.count <= index { return false }
		return _store[index] != nil
	}

	public func get(at index: Int) -> Element? {
		return _store[index]
	}

	public func remove(at index: Int) {
		if _store[index] != nil {
			_count -= 1
		}
		return _store[index] = nil
	}

	internal func needsToGrow(_ index: Int) -> Bool {
		return index > _store.count - 1
	}

	internal func grow(including index: Int) {
		//var t = Timer()
		//t.start()
		let newCapacity: Int = nearest(to: index)
		let count: Int = newCapacity-_store.count
		//_store.reserveCapacity(newCapacity)
		for _ in 0..<count {
			_store.append(nil)
		}
		//t.stop()
		//print("did grow to \(newCapacity) in \(t.milliSeconds)ms")
	}

	internal func nearest(to index: Int) -> Int {
		let delta = Float(index) / Float(ManagedContiguousArray.chunkSize)
		let multiplier = Int(delta) + 1
		return multiplier * ManagedContiguousArray.chunkSize
	}
}

public class ContiguousComponentArray: ManagedContiguousArray {
		public typealias Element = Component
}

public class ContiguousEntityIdArray: ManagedContiguousArray {
	public typealias Element = EntityIdentifier
}

/*
	public func insert(_ element: Element, at entityIdx: EntityIndex) {
		super.insert(element, at: entityIdx)
	}

	public func has(_ entityIdx: EntityIndex) -> Bool {
		if _store.count <= entityIdx { return false }
		return _store[entityIdx] != nil
	}

	public func get(at entityIdx: EntityIndex) -> Element? {
		return _store[entityIdx]
	}

	public func remove(at entityIdx: EntityIndex) {
		return _store[entityIdx] = nil
	}

	fileprivate func needsToGrow(_ entityId: EntityIndex) -> Bool {
		return entityId > _store.count - 1
	}

	fileprivate func grow(to minIndex: Int) {

			let newCapacity: Int = nearestToPow2(minIndex)
			let count: Int = newCapacity-_store.count
			let nilElements: ContiguousArray<Element?> = ContiguousArray<Element?>.init(repeating: nil, count: count)

			_store.reserveCapacity(newCapacity)
			_store.append(contentsOf: nilElements)

	}

*/
