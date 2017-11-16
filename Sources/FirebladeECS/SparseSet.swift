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
	var capacitySparse: Int { return sparse.capacity }
	var capacityDense: Int { return dense.capacity }

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

	public func get(at index: Index) -> Element? {
		guard has(index) else { return nil }
		return dense[sparse[index]!]!.value
	}

	public func remove(at index: Index) {
		guard has(index) else { return }
		let removeIdx: DenseIndex = sparse[index]!
		let lastIdx: DenseIndex = count-1
		dense.swapAt(removeIdx, lastIdx)
		sparse[index] = nil
		let swapped: Pair = dense[removeIdx]!
		sparse[swapped.key] = removeIdx
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

	public func makeIterator() -> SparseSetIterator<Element> {
		return SparseSetIterator<Element>(self)
	}

	// MARK: - SparseIterator
	public struct SparseSetIterator<Element>: IteratorProtocol {
		private let sparseSet: SparseSet<Element>
		private var iterator: IndexingIterator<ContiguousArray<(key: Index, value: Element)?>>
		init(_ sparseSet: SparseSet<Element>) {
			self.sparseSet = sparseSet
			self.iterator = sparseSet.dense.makeIterator()
		}

		mutating public func next() -> Element? {
			guard let next: Pair = iterator.next() as? Pair else { return nil }
			return next.value as? Element
		}

	}
}

// MARK: - specialized sparse sets

public class SparseComponentSet: SparseSet<Component> {
	public typealias Index = EntityIndex

}

public class SparseEntityIdentifierSet: SparseSet<EntityIdentifier> {
	public typealias Index = EntityIndex

}
