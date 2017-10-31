//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseComponentSet {
	public typealias Element = Component
	fileprivate typealias ComponentIdx = Int
	fileprivate var size: Int = 0
	fileprivate var dense: ContiguousArray<Pair?>
	fileprivate var sparse: [EntityIndex: ComponentIdx]
	fileprivate typealias Pair = (key: EntityIndex, value: Element)

	public init() {
		dense = ContiguousArray<Pair?>()
		sparse = [EntityIndex: ComponentIdx]()
	}

	deinit {
		clear()
	}

	public var count: Int { return size }
	internal var capacitySparse: Int { return sparse.capacity }
	internal var capacityDense: Int { return dense.capacity }

	public func contains(_ entityIdx: EntityIndex ) -> Bool {
		return sparse[entityIdx] != nil &&
			sparse[entityIdx]! < count &&
			dense[sparse[entityIdx]!] != nil
	}

	@discardableResult
	public func add(_ element: Element, with entityIdx: EntityIndex ) -> Bool {
		if contains(entityIdx) { return false }
		sparse[entityIdx] = count
		let entry: Pair = Pair(key: entityIdx, value: element)
		dense.append(entry)
		size += 1
		return true
	}

	public func get(at entityIdx: EntityIndex) -> Element? {
		guard contains(entityIdx) else { return nil }
		return dense[sparse[entityIdx]!]!.value
	}

	@discardableResult
	public func remove(_ entityIdx: EntityIndex ) -> Element? {
		guard contains(entityIdx) else { return nil }
		let compIdx: ComponentIdx = sparse[entityIdx]!
		let lastIdx: ComponentIdx = count-1
		dense.swapAt(compIdx, lastIdx)
		sparse[entityIdx] = nil
		let swapped: Pair = dense[compIdx]!
		sparse[swapped.key] = compIdx
		let removed: Pair = dense.popLast()!!
		size -= 1
		if size == 0 {
			clear(keepingCapacity: false)
		}
		return removed.value
	}

	public func clear(keepingCapacity: Bool = false) {
		size = 0
		dense.removeAll(keepingCapacity: keepingCapacity)
		sparse.removeAll(keepingCapacity: keepingCapacity)
	}

}

extension SparseComponentSet: Sequence {

	public func makeIterator() -> AnyIterator<Element> {
		var iterator = dense.makeIterator()
		return AnyIterator<Element> {
			iterator.next()??.value
		}
	}
}
