//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseComponentSet {
	public typealias Element = Component
	public let chunkSize: Int = 4096
	fileprivate typealias ComponentIdx = Int
	fileprivate var size: Int = 0

	fileprivate class Pair {
		let key: EntityIndex
		let value: Element
		init(key: EntityIndex, value: Element) {
			self.key = key
			self.value = value
		}
	}

	fileprivate var dense: ContiguousArray<Pair?>
	fileprivate var sparse: [EntityIndex: ComponentIdx]

	public init() {
		dense = ContiguousArray<Pair?>()
		dense.reserveCapacity(chunkSize)
		sparse = [EntityIndex: ComponentIdx].init(minimumCapacity: chunkSize)
	}

	public var count: Int { return size }
	internal var capacitySparse: Int { return sparse.count }
	internal var capacityDense: Int { return dense.count }

	public func contains(_ entityIdx: EntityIndex ) -> Bool {
		guard let compIdx: ComponentIdx = sparse[entityIdx] else { return false }
		return compIdx < count && dense[compIdx] != nil
	}

	@discardableResult
	public func add(_ element: Element, with entityIdx: EntityIndex ) -> Bool {
		if contains(entityIdx) { return false }
		if needsToGrow(entityIdx) {
			grow(including: entityIdx)
		}
		sparse[entityIdx] = count
		let entry: Pair = Pair(key: entityIdx, value: element)
		dense.append(entry)
		size += 1
		return true
	}

	public func get(at entityIdx: EntityIndex) -> Element? {
		guard let compIdx: ComponentIdx = sparse[entityIdx] else { return nil }
		return dense[compIdx]!.value
	}

	@discardableResult
	public func remove(_ entityIdx: EntityIndex ) -> Element? {
		guard let compIdx: ComponentIdx = sparse[entityIdx] else { return nil }
		let last: Int = count-1
		dense.swapAt(compIdx, last)
		sparse[entityIdx] = nil
		let swapped: Pair = dense[compIdx]!
		sparse[swapped.key] = compIdx
		let removed: Pair = dense.popLast()!!
		size -= 1
		return removed.value
	}

	public func clear(keepingCapacity: Bool = false) {
		dense.removeAll(keepingCapacity: keepingCapacity)
	}

	fileprivate func needsToGrow(_ index: Int) -> Bool {
		return index > count - 1
	}

	fileprivate func grow(including index: Int) {
		let newCapacity: Int = nearest(to: index)
		//let newCount: Int = newCapacity-count
		dense.reserveCapacity(newCapacity)
		/*for _ in 0..<newCount {
			dense.append(nil)
		}*/
	}

	fileprivate func nearest(to index: Int) -> Int {
		let delta = Float(index) / Float(chunkSize)
		let multiplier = Int(delta) + 1
		return multiplier * chunkSize
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
