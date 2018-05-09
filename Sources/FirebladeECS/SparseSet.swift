//
//  SparseSet.swift
//  FirebladeECS
//
//  Created by Christian Treffs on 30.10.17.
//

public class SparseSet<Element>: UniformStorage, Sequence {
	public typealias Index = Int
	private typealias DenseIndex = Int
	private var size: Int = 0
	private var denseIndices: ContiguousArray<Index>
	private var denseData: ContiguousArray<Element>
	private var sparse: [Index: DenseIndex]

    // TODO: implement
    // a) RandomAccessCollection conformance
    // b) subscript

	public init() {
		denseIndices = ContiguousArray<Index>()
		denseData = ContiguousArray<Element>()
		sparse = [Index: DenseIndex]()
	}

	deinit {
		clear()
	}

	public var count: Int { return size }
	public var isEmpty: Bool { return size == 0 }

	public func has(_ index: Index) -> Bool {
		return sparse[index] ?? Int.max < count /*&&
			denseIndices[safe: sparse[index]!] != nil*/
	}

	public func add(_ element: Element, at index: Index) {
		if has(index) {
			return
		}
		sparse[index] = count
		denseIndices.append(index)
		denseData.append(element)
		size += 1
	}

	public func get(at index: Index) -> Element? {
		guard let sIdx: Index = sparse[index] else {
			return nil
		}
		return denseData[sIdx]
	}

	@discardableResult
	public func remove(at index: Index) -> Bool {
		guard has(index), let removeIdx: DenseIndex = sparse[index] else {
			return false
		}

		let lastIdx: DenseIndex = count - 1
		denseIndices.swapAt(removeIdx, lastIdx)
		denseData.swapAt(removeIdx, lastIdx)
		sparse[index] = nil
        let swappedIndex: Index = denseIndices[removeIdx]
		sparse[swappedIndex] = removeIdx
		denseIndices.removeLast()
		denseData.removeLast()
		size -= 1
		if size == 0 {
			clear(keepingCapacity: false)
		}
		return true
	}

	public func clear(keepingCapacity: Bool = false) {
		size = 0
		denseIndices.removeAll(keepingCapacity: keepingCapacity)
		denseData.removeAll(keepingCapacity: keepingCapacity)
		sparse.removeAll(keepingCapacity: keepingCapacity)
	}

	public func makeIterator() -> SparseSetIterator<Element> {
		return SparseSetIterator<Element>(self)
	}

	// MARK: - SparseIterator
	public struct SparseSetIterator<Element>: IteratorProtocol {
		private let sparseSet: SparseSet<Element>
		private var iterator: IndexingIterator<ContiguousArray<Element>>

		init(_ sparseSet: SparseSet<Element>) {
			self.sparseSet = sparseSet
			self.iterator = sparseSet.denseData.makeIterator()
		}

		mutating public func next() -> Element? {
			return iterator.next()
		}

	}
}

// MARK: - Equatable
extension SparseSet: Equatable where SparseSet.Element: Equatable {
    public static func == (lhs: SparseSet<Element>, rhs: SparseSet<Element>) -> Bool {
        return lhs.denseIndices == rhs.denseIndices &&
        lhs.denseData == rhs.denseData &&
        lhs.sparse == rhs.sparse
    }
}

// MARK: - specialized sparse sets

public class SparseEntitySet: SparseSet<Entity> {
	public typealias Index = EntityIndex
}

public class SparseEntityIdentifierSet: SparseSet<EntityIdentifier> {
	public typealias Index = EntityIndex

}

public class SparseComponentIdentifierSet: SparseSet<ComponentIdentifier> {

}
