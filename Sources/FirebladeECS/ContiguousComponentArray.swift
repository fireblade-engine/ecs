//
//  ContiguousComponentArray.swift
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

public class ContiguousComponentArray {
	public typealias Element = Component

	private var _store: ContiguousArray<Element?>

	public init(minEntityCount minCount: Int) {
		let count = nearestToPow2(minCount)
		_store = ContiguousArray<Element?>(repeating: nil, count: count)
	}

	public func insert(_ element: Element, at entityIdx: EntityIndex) {

		if needsToGrow(entityIdx) {
			grow(to: entityIdx)
		}
		_store[entityIdx] = element
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
		if minIndex >= _store.count {
			let newCapacity: Int = nearestToPow2(minIndex)
			let count: Int = newCapacity-_store.count
			let nilElements: ContiguousArray<Element?> = ContiguousArray<Element?>.init(repeating: nil, count: count)

			_store.reserveCapacity(newCapacity)
			_store.append(contentsOf: nilElements)
		}
	}

}
