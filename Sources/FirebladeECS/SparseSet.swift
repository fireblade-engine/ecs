//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseSet<Element>: UniformStorage, Sequence {
	public typealias Index = Int
	fileprivate typealias DenseIndex = Int
	fileprivate var size: Int = 0
	fileprivate var dense: ContiguousArray<Pair?>
	fileprivate var sparse: [Index: DenseIndex]
	fileprivate typealias Pair = (key: Index, value: Element)

	public init() {
		dense = ContiguousArray<Pair?>()
		sparse = [Index: DenseIndex]()
	}

	deinit {
		clear()
	}

	public var count: Int { return size }
	internal var capacitySparse: Int { return sparse.capacity }
	internal var capacityDense: Int { return dense.capacity }

	public func has(_ index: Index) -> Bool {
		return sparse[index] ?? Int.max < count &&
			dense[sparse[index]!] != nil
	}

	public func add(_ element: Element, at index: Index) {
		if has(index) { return }
		sparse[index] = count
		let entry: Pair = Pair(key: index, value: element)
		dense.append(entry)
		size += 1
	}

	public func get(at entityIdx: Index) -> Element? {
		guard has(entityIdx) else { return nil }
		return dense[sparse[entityIdx]!]!.value
	}

	public func remove(at index: Index) {
		guard has(index) else { return }
		let compIdx: DenseIndex = sparse[index]!
		let lastIdx: DenseIndex = count-1
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

	public func makeIterator() -> AnyIterator<Element> {
		var iter = dense.makeIterator()
		return AnyIterator<Element> {
			guard let next: Pair? = iter.next() else { return nil }
			guard let pair: Pair = next else { return nil }
			return pair.value
		}
	}

}

public class SparseComponentSet: SparseSet<Component> {
	public typealias Index = EntityIndex

}

public class SparseEntityIdentifierSet: SparseSet<EntityIdentifier> {
	public typealias Index = EntityIndex

}
