//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseSet: UniformStorage {

	public typealias Element = Any
	public typealias Index = Int
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

	public func has(_ index: EntityIndex) -> Bool {
		return sparse[index] ?? Int.max < count &&
			dense[sparse[index]!] != nil
	}

	public func add(_ element: Element, at index: EntityIndex) {
		if has(index) { return }
		sparse[index] = count
		let entry: Pair = Pair(key: index, value: element)
		dense.append(entry)
		size += 1
	}

	public func get(at entityIdx: EntityIndex) -> Element? {
		guard has(entityIdx) else { return nil }
		return dense[sparse[entityIdx]!]!.value
	}

	public func remove(at index: EntityIndex) {
		guard has(index) else { return }
		let compIdx: ComponentIdx = sparse[index]!
		let lastIdx: ComponentIdx = count-1
		dense.swapAt(compIdx, lastIdx)
		sparse[index] = nil
		let swapped: Pair = dense[compIdx]!
		sparse[swapped.key] = compIdx
		_ = dense.popLast()!!
		size -= 1
		if size == 0 {
			clear(keepingCapacity: false)
		}
	}

	public func clear(keepingCapacity: Bool = false) {
		size = 0
		dense.removeAll(keepingCapacity: keepingCapacity)
		sparse.removeAll(keepingCapacity: keepingCapacity)
	}

}

extension SparseSet: Sequence {

	public func makeIterator() -> AnyIterator<Element> {
		var iterator = dense.makeIterator()
		return AnyIterator<Element> {
			iterator.next()??.value
		}
	}
}

public class SparseComponentSet: SparseSet {
	public typealias Element = Component
	public typealias Index = EntityIndex
}
